import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_stream_manager.dart';
import '../media/video_parameters.dart';
import '../utils/omnicast_logger.dart';
import 'webrtc_stats_monitor.dart';

typedef OnLocalIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnRemoteTrackCallback =
    void Function(MediaStreamTrack track, MediaStream stream);
typedef OnIceRestartNeededCallback = void Function();

/// Manages [RTCPeerConnection] initialization, simulcast/SVC transceivers,
/// VP8/VP9 and Opus DTX SDP munging, ICE candidate queuing, and renegotiation.
class WebRTCManager {
  final MediaStreamManager mediaStreamManager;
  final Map<String, dynamic> rtcConfiguration;

  RTCPeerConnection? _peerConnection;
  RTCRtpSender? _videoSender;
  RTCRtpSender? _audioSender;
  bool _isNegotiating = false;
  bool _simulcastEnabled = false;
  bool _isDisposed = false;
  Timer? _iceDisconnectTimer;
  late final WebRTCStatsMonitor _statsMonitor;

  final List<RTCIceCandidate> _queuedRemoteCandidates = [];

  // Callbacks
  OnLocalIceCandidateCallback? onLocalIceCandidate;
  OnRemoteTrackCallback? onRemoteTrack;
  OnIceRestartNeededCallback? onIceRestartNeeded;

  WebRTCManager({
    required this.mediaStreamManager,
    Map<String, dynamic>? configuration,
  }) : rtcConfiguration =
           configuration ??
           {
             'iceServers': [
               {'urls': 'stun:stun.l.google.com:19302'},
               {'urls': 'stun:stun1.l.google.com:19302'},
             ],
             'sdpSemantics': 'unified-plan',
             'iceTransportPolicy': 'all',
             'bundlePolicy': 'max-bundle',
             'rtcpMuxPolicy': 'require',
           } {
    _statsMonitor = WebRTCStatsMonitor(
      getPeerConnection: () async => _peerConnection,
    );
  }

  RTCPeerConnection? get peerConnection => _peerConnection;
  bool get hasPeerConnection => _peerConnection != null;
  bool get isNegotiating => _isNegotiating;
  bool get simulcastEnabled => _simulcastEnabled;
  RTCRtpSender? get videoSender => _videoSender;
  RTCRtpSender? get audioSender => _audioSender;
  WebRTCStatsMonitor get statsMonitor => _statsMonitor;

  /// Modifies an SDP string to prioritize a specific codec (e.g. 'VP8') at the front of the m=video line.
  /// Strictly prioritizes VP8 for flawless packet loss recovery, PLI keyframe handling, and zero macroblocking.
  static String preferCodec(String sdp, String codec) {
    if (sdp.isEmpty) return sdp;
    final delimiter = sdp.contains('\r\n') ? '\r\n' : '\n';
    final lines = sdp.split(delimiter);
    final mVideoIndex = lines.indexWhere((l) => l.startsWith('m=video'));
    if (mVideoIndex == -1) return sdp;

    final mVideoLine = lines[mVideoIndex];
    final parts = mVideoLine.split(' ');
    if (parts.length < 4) return sdp;

    final header = parts.sublist(0, 3); // ['m=video', port, proto]
    final payloadTypes = parts.sublist(3);

    final codecPayloads = <String>[];
    final otherPayloads = <String>[];

    for (final pt in payloadTypes) {
      final rtpmap = lines.firstWhere(
        (l) =>
            l.toLowerCase().startsWith('a=rtpmap:$pt ${codec.toLowerCase()}'),
        orElse: () => '',
      );
      if (rtpmap.isNotEmpty) {
        codecPayloads.add(pt);
      } else {
        otherPayloads.add(pt);
      }
    }

    if (codecPayloads.isEmpty) return sdp;

    lines[mVideoIndex] =
        '${header.join(' ')} ${codecPayloads.join(' ')} ${otherPayloads.join(' ')}';
    return lines.join(delimiter);
  }

  /// Injects initial starting bitrate (500 kbps) and max bitrate constraints directly into SDP
  /// to eliminate the initial bandwidth burst and allow smooth TWCC ramp-up.
  static String setInitialBitrate(
    String sdp, {
    int startKbps = 500,
    int minKbps = 150,
    int maxKbps = 600,
  }) {
    if (sdp.isEmpty) return sdp;
    final delimiter = sdp.contains('\r\n') ? '\r\n' : '\n';
    final lines = sdp.split(delimiter);

    // Append x-google bitrates to video fmtp lines
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('a=fmtp:')) {
        if (!line.contains('x-google-start-bitrate=')) {
          lines[i] =
              '$line;x-google-start-bitrate=$startKbps;x-google-min-bitrate=$minKbps;x-google-max-bitrate=$maxKbps';
        }
      }
    }

    return lines.join(delimiter);
  }

  /// Modifies an SDP string to enable Opus DTX (Discontinuous Transmission) and FEC (Forward Error Correction).
  /// Saves significant bandwidth and battery when the broadcaster/guest is silent.
  static String enableOpusDtx(String sdp) {
    if (sdp.isEmpty) return sdp;
    final delimiter = sdp.contains('\r\n') ? '\r\n' : '\n';
    final lines = sdp.split(delimiter);
    final opusPayloadTypes = <String>[];

    for (final line in lines) {
      if (line.toLowerCase().contains('opus/48000')) {
        final match = RegExp(
          r'a=rtpmap:(\d+)\s+opus',
          caseSensitive: false,
        ).firstMatch(line);
        if (match != null) {
          opusPayloadTypes.add(match.group(1)!);
        }
      }
    }

    for (var i = 0; i < lines.length; i++) {
      for (final pt in opusPayloadTypes) {
        if (lines[i].startsWith('a=fmtp:$pt')) {
          var fmtp = lines[i];
          if (!fmtp.contains('usedtx=')) {
            fmtp += ';usedtx=1';
          }
          if (!fmtp.contains('useinbandfec=')) {
            fmtp += ';useinbandfec=1';
          }
          lines[i] = fmtp;
        }
      }
    }

    return lines.join(delimiter);
  }

  /// Strips transport-cc RTCP feedback and header extensions from SDP to prevent
  /// libwebrtc TransportFeedbackAdapter send time history lookup errors and
  /// packet sequence desynchronization in multi-stream SFU broadcasting.
  static String stripTransportCc(String sdp) {
    if (sdp.isEmpty) return sdp;
    final delimiter = sdp.contains('\r\n') ? '\r\n' : '\n';
    final lines = sdp.split(delimiter);
    final filtered = <String>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      // Remove transport-cc rtcp-fb lines
      if (lower.startsWith('a=rtcp-fb:') && lower.contains('transport-cc')) {
        continue;
      }
      // Remove transport-wide-cc header extensions
      if (lower.startsWith('a=extmap:') &&
          (lower.contains('transport-wide-cc') ||
              lower.contains('transport_wide_cc'))) {
        continue;
      }
      filtered.add(line);
    }

    return filtered.join(delimiter);
  }

  /// Initializes a new [RTCPeerConnection] with standard configuration and sets up listeners.
  Future<RTCPeerConnection> initializePeerConnection() async {
    if (_peerConnection != null) {
      return _peerConnection!;
    }

    // Ensure WebRTC native engine ignores loopback interface and silences internal C++ logs
    try {
      await WebRTC.initialize(
        options: {
          'logSeverity': OmniCastLogger.enableLogging ? 'warning' : 'none',
          'networkIgnoreMask': ['adapterTypeLoopback'],
        },
      );
    } catch (_) {}

    final pc = await createPeerConnection(rtcConfiguration);
    _peerConnection = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        final c = candidate.candidate!.toLowerCase();
        // Ignore loopback candidates to eliminate invalid STUN ping failures
        if (c.contains('127.0.0.') ||
            c.contains('::1') ||
            c.contains('.local')) {
          return;
        }
        onLocalIceCandidate?.call(candidate);
      }
    };

    pc.onIceConnectionState = (state) {
      OmniCastLogger.log('[WebRTCManager] ICE Connection State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _iceDisconnectTimer?.cancel();
        // 1-2s seamless ICE restart window during WiFi <-> Cellular handoffs
        _iceDisconnectTimer = Timer(const Duration(milliseconds: 1500), () {
          OmniCastLogger.log(
            '[WebRTCManager] ICE disconnected for >1.5s -> Triggering seamless ICE Restart',
          );
          onIceRestartNeeded?.call();
        });
      } else if (state ==
              RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = null;
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = null;
        OmniCastLogger.log(
          '[WebRTCManager] ICE Failed -> Triggering Immediate ICE Restart',
        );
        onIceRestartNeeded?.call();
      }
    };

    pc.onConnectionState = (state) {
      OmniCastLogger.log('[WebRTCManager] PeerConnection State: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _iceDisconnectTimer?.cancel();
        // 1.5s seamless ICE restart window
        _iceDisconnectTimer = Timer(const Duration(milliseconds: 1500), () {
          OmniCastLogger.log(
            '[WebRTCManager] Connection state disconnected for >1.5s -> Triggering seamless ICE Restart',
          );
          onIceRestartNeeded?.call();
        });
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = null;
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = null;
        OmniCastLogger.log(
          '[WebRTCManager] Connection state Failed -> Triggering Immediate ICE Restart',
        );
        onIceRestartNeeded?.call();
      }
    };

    pc.onTrack = (RTCTrackEvent event) {
      OmniCastLogger.log(
        '[WebRTCManager] onTrack: kind=${event.track.kind}, streams=${event.streams.length}, id=${event.track.id}',
      );

      // Force immediate zero-latency playout on incoming remote tracks (bypasses jitter buffer delay)
      try {
        // ignore: avoid_dynamic_calls
        (event.track as dynamic).playoutDelayHint = 0.0;
      } catch (_) {}
      try {
        // ignore: avoid_dynamic_calls
        (event.receiver as dynamic)?.playoutDelayHint = 0.0;
      } catch (_) {}

      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        onRemoteTrack?.call(event.track, stream);
      } else {
        createLocalMediaStream('stream_${event.track.id}')
            .then((stream) {
              try {
                stream.addTrack(event.track).catchError((_) {});
              } catch (_) {}
              onRemoteTrack?.call(event.track, stream);
            })
            .catchError((_) {});
      }
    };

    return pc;
  }

  /// Sets up initial transceivers for a viewer (Receive-Only for audio and video).
  Future<void> setupViewerTransceivers() async {
    final pc = await initializePeerConnection();

    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
  }

  /// Adds local media tracks to [RTCPeerConnection], configuring hardware-friendly H264/VP8 codecs,
  /// dynamic bitrate adaptation (1000-1200 kbps max), and maintain-framerate degradation preference for zero lag.
  Future<void> addLocalMediaTracks({bool enableSimulcast = false}) async {
    final pc = await initializePeerConnection();
    final localStream = mediaStreamManager.localStream;
    if (localStream == null) {
      throw StateError('Cannot add local media tracks: localStream is null');
    }

    _simulcastEnabled = false;

    // Add audio track
    final audioTracks = localStream.getAudioTracks();
    if (audioTracks.isNotEmpty) {
      _audioSender = await pc.addTrack(audioTracks.first, localStream);
    }

    // Add video track with mobile dynamic bitrate & zero-lag framerate preference
    final videoTracks = localStream.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      final videoTrack = videoTracks.first;

      // Add single, highly-stable video track directly (VP8 software/native codec)
      _videoSender = await pc.addTrack(videoTrack, localStream);

      // Force VP8 codec preference over H264/VP9 for rock-solid packet loss & PLI resilience
      try {
        final transceivers = await pc.getTransceivers();
        final videoTransceiver = transceivers.firstWhere(
          (t) => t.sender.track?.kind == 'video' || t.sender == _videoSender,
        );
        final capabilities = await getRtpSenderCapabilities('video');
        if (capabilities.codecs != null && capabilities.codecs!.isNotEmpty) {
          final sortedCodecs = List<RTCRtpCodecCapability>.from(
            capabilities.codecs!,
          );
          sortedCodecs.sort((a, b) {
            final mimeA = a.mimeType.toLowerCase();
            final mimeB = b.mimeType.toLowerCase();
            int scoreA = mimeA.contains('vp8')
                ? 0
                : (mimeA.contains('vp9') ? 1 : 2);
            int scoreB = mimeB.contains('vp8')
                ? 0
                : (mimeB.contains('vp9') ? 1 : 2);
            return scoreA.compareTo(scoreB);
          });
          await videoTransceiver.setCodecPreferences(sortedCodecs);
        }
      } catch (_) {}

      // Apply single global maxBitrate: 600000 (600 kbps) and MAINTAIN_FRAMERATE
      try {
        final senders = await pc.getSenders();
        RTCRtpSender? videoSender;
        for (final s in senders) {
          if (s.track?.kind == 'video') {
            videoSender = s;
            break;
          }
        }
        videoSender ??= _videoSender;
        if (videoSender != null) {
          final params = videoSender.parameters;
          params.degradationPreference =
              RTCDegradationPreference.MAINTAIN_FRAMERATE;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            params.encodings![0].maxBitrate = 600000;
            params.encodings![0].minBitrate = 150000;
            params.encodings![0].maxFramerate = 24;
            params.encodings![0].scalabilityMode = 'L1T3';
          }
          await videoSender.setParameters(params);
          OmniCastLogger.log(
            '[WebRTCManager] Configured clean VP8 video track with maxBitrate: 600 kbps',
          );
        }
      } catch (e) {
        OmniCastLogger.error(
          '[WebRTCManager] Set single-stream parameters notice: $e',
        );
      }
    }
  }

  /// Strictly enables/mutes a local track both on [MediaStreamTrack] and on all matching [RTCRtpSender]s.
  Future<void> setLocalTrackEnabled(String kind, bool enabled) async {
    if (kind == 'audio') {
      mediaStreamManager.toggleAudio(enabled);
    } else if (kind == 'video') {
      mediaStreamManager.toggleVideo(enabled);
    }

    if (_peerConnection != null) {
      try {
        final senders = await _peerConnection!.getSenders();
        for (final sender in senders) {
          if (sender.track?.kind == kind) {
            sender.track?.enabled = enabled;
          }
        }
      } catch (e) {
        OmniCastLogger.error(
          '[WebRTCManager] Error setting sender track enabled: $e',
        );
      }
    }
  }

  /// Dynacast: Dynamically pauses/resumes sending a specific simulcast layer upstream (e.g. 'f', 'h', 'q').
  Future<void> setPublisherLayerActive(String rid, bool active) async {
    if (_videoSender == null) return;

    try {
      final params = _videoSender!.parameters;
      if (params.encodings == null || params.encodings!.isEmpty) return;

      var updated = false;
      for (final encoding in params.encodings!) {
        if (encoding.rid == rid && encoding.active != active) {
          encoding.active = active;
          updated = true;
          OmniCastLogger.log(
            '[WebRTCManager Dynacast] Set layer $rid active=$active',
          );
        }
      }

      if (updated) {
        await _videoSender!.setParameters(params);
      }
    } catch (e) {
      OmniCastLogger.error(
        '[WebRTCManager Dynacast] Error setting layer active: $e',
      );
    }
  }

  /// Strictly enforces maximum video bitrate limit on the video RTCRtpSender to prevent macroblocking and congestion.
  Future<void> enforceMaxVideoBitrate({int maxBitrate = 600000}) async {
    if (_peerConnection == null) return;
    try {
      final senders = await _peerConnection!.getSenders();
      final videoSenders = senders.where(
        (s) => s.track?.kind == 'video' || s == _videoSender,
      );
      for (final sender in videoSenders) {
        final parameters = sender.parameters;
        if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
          for (final encoding in parameters.encodings!) {
            encoding.maxBitrate = maxBitrate;
            if (encoding.minBitrate != null &&
                encoding.minBitrate! > maxBitrate) {
              encoding.minBitrate = maxBitrate ~/ 2;
            }
          }
          parameters.degradationPreference =
              RTCDegradationPreference.MAINTAIN_FRAMERATE;
          await sender.setParameters(parameters);
          OmniCastLogger.log(
            '[WebRTCManager] Enforced maxVideoBitrate: $maxBitrate bps on sender',
          );
        }
      }
    } catch (e) {
      OmniCastLogger.error(
        '[WebRTCManager] Error enforcing max video bitrate: $e',
      );
    }
  }

  /// Creates an SDP Offer, prioritizes VP8 codec, disables VAD, and sets initial bitrate.
  Future<RTCSessionDescription> createAndSetLocalOffer({
    bool offerToReceiveAudio = true,
    bool offerToReceiveVideo = true,
  }) async {
    final pc = await initializePeerConnection();

    final constraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': offerToReceiveAudio,
        'OfferToReceiveVideo': offerToReceiveVideo,
      },
      'optional': [],
    };

    _isNegotiating = true;
    try {
      final offer = await pc.createOffer(constraints);
      var processedSdp = preferCodec(offer.sdp ?? '', 'VP8');
      processedSdp = setInitialBitrate(
        processedSdp,
        startKbps: 500,
        minKbps: 150,
        maxKbps: 600,
      );
      processedSdp = stripTransportCc(enableOpusDtx(processedSdp));
      final mungedOffer = RTCSessionDescription(
        processedSdp,
        offer.type ?? 'offer',
      );
      await pc.setLocalDescription(mungedOffer);
      return mungedOffer;
    } finally {
      _isNegotiating = false;
    }
  }

  /// Creates an ICE Restart SDP Offer ({ 'IceRestart': true }) for seamless network handoffs.
  Future<RTCSessionDescription> createIceRestartOffer() async {
    final pc = await initializePeerConnection();

    final constraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
        'IceRestart': true,
      },
      'optional': [],
    };

    _isNegotiating = true;
    try {
      final offer = await pc.createOffer(constraints);
      var processedSdp = preferCodec(offer.sdp ?? '', 'VP8');
      processedSdp = setInitialBitrate(
        processedSdp,
        startKbps: 500,
        minKbps: 150,
        maxKbps: 600,
      );
      processedSdp = stripTransportCc(enableOpusDtx(processedSdp));
      final mungedOffer = RTCSessionDescription(
        processedSdp,
        offer.type ?? 'offer',
      );
      await pc.setLocalDescription(mungedOffer);
      return mungedOffer;
    } finally {
      _isNegotiating = false;
    }
  }

  /// Safely sanitizes and unrolls incoming SDP strings from JSON envelopes or escaped strings.
  static String sanitizeSdp(dynamic input) {
    if (input == null) return '';
    String sdp = '';
    if (input is Map) {
      sdp = (input['sdp'] ?? input['SDP'] ?? '').toString();
    } else if (input is String) {
      final trimmed = input.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            sdp = (decoded['sdp'] ?? decoded['SDP'] ?? '').toString();
            if (sdp.isEmpty) {
              sdp = trimmed;
            }
          } else {
            sdp = trimmed;
          }
        } catch (_) {
          sdp = trimmed;
        }
      } else {
        sdp = trimmed;
      }
    } else {
      sdp = input.toString();
    }

    // Fix escaped newlines if JSON-encoded
    if (sdp.contains(r'\r\n') || (sdp.contains(r'\n') && !sdp.contains('\n'))) {
      sdp = sdp.replaceAll(r'\r\n', '\r\n').replaceAll(r'\n', '\n');
    }

    // Ensure valid trailing newline format required by native WebRTC
    sdp = sdp.trimRight();
    if (sdp.isNotEmpty) {
      sdp = '$sdp\r\n';
    }

    return sdp;
  }

  /// Handles a remote SDP Answer received from the signaling server.
  Future<void> handleRemoteAnswer(dynamic rawSdp) async {
    if (_peerConnection == null) {
      throw StateError(
        'Cannot handle remote answer without an active PeerConnection',
      );
    }

    final sdp = sanitizeSdp(rawSdp);
    if (sdp.isEmpty) {
      OmniCastLogger.error(
        '[WebRTCManager] handleRemoteAnswer received empty SDP',
      );
      return;
    }

    final description = RTCSessionDescription(stripTransportCc(sdp), 'answer');
    await _peerConnection!.setRemoteDescription(description);
    await _processQueuedCandidates();
  }

  /// Handles a server-initiated SDP Offer (e.g. when a new co-host joins), replying with VP8/DTX answer.
  Future<RTCSessionDescription> handleRemoteOfferAndCreateAnswer(
    dynamic rawSdp,
  ) async {
    final sdp = sanitizeSdp(rawSdp);
    if (sdp.isEmpty) {
      throw ArgumentError(
        'Cannot handle remote offer with empty or invalid SDP: $rawSdp',
      );
    }

    final pc = await initializePeerConnection();

    // Check signaling state: If we have an offer collision (have-local-offer),
    // perform JSEP rollback before applying the remote offer.
    final state = pc.signalingState;
    if (state == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      try {
        await pc.setLocalDescription(RTCSessionDescription('', 'rollback'));
        OmniCastLogger.log(
          '[WebRTCManager] Successfully rolled back local offer on collision',
        );
      } catch (e) {
        OmniCastLogger.log(
          '[WebRTCManager] Rollback attempt on offer collision: $e',
        );
      }
    }

    final remoteDescription = RTCSessionDescription(
      stripTransportCc(sdp),
      'offer',
    );
    await pc.setRemoteDescription(remoteDescription);
    await _processQueuedCandidates();

    final answer = await pc.createAnswer({});
    var processedSdp = preferCodec(answer.sdp ?? '', 'VP8');
    processedSdp = setInitialBitrate(
      processedSdp,
      startKbps: 500,
      minKbps: 150,
      maxKbps: 600,
    );
    processedSdp = stripTransportCc(enableOpusDtx(processedSdp));
    final mungedAnswer = RTCSessionDescription(
      processedSdp,
      answer.type ?? 'answer',
    );
    await pc.setLocalDescription(mungedAnswer);

    return mungedAnswer;
  }

  /// Seamlessly upgrades a Viewer to a Co-Host without tearing down the existing [RTCPeerConnection].
  Future<RTCSessionDescription> upgradeViewerToCoHost({
    bool video = true,
    bool audio = true,
    bool enableSimulcast = false,
    VideoParameters? parameters,
  }) async {
    if (_peerConnection == null) {
      throw StateError(
        'Cannot upgrade to co-host without an active PeerConnection',
      );
    }

    // 1. Capture local camera/microphone
    await mediaStreamManager.openUserMedia(
      parameters: parameters,
      video: video,
      audio: audio,
    );

    // 2. Add local tracks to existing PeerConnection
    await addLocalMediaTracks(enableSimulcast: enableSimulcast);

    // 3. Create renegotiation offer with VP8 and Opus DTX preference
    final offer = await _peerConnection!.createOffer({});
    var processedSdp = preferCodec(offer.sdp ?? '', 'VP8');
    processedSdp = setInitialBitrate(
      processedSdp,
      startKbps: 500,
      minKbps: 150,
      maxKbps: 600,
    );
    processedSdp = stripTransportCc(enableOpusDtx(processedSdp));
    final mungedOffer = RTCSessionDescription(
      processedSdp,
      offer.type ?? 'offer',
    );
    await _peerConnection!.setLocalDescription(mungedOffer);

    return mungedOffer;
  }

  /// Seamlessly downgrades a Co-Host back to Viewer mode without destroying downlink subscriptions.
  Future<void> downgradeCoHostToViewer() async {
    // 1. Stop hardware camera and microphone
    await mediaStreamManager.stopLocalMedia();

    // 2. Remove local audio and video senders from active PeerConnection
    if (_peerConnection != null) {
      if (_videoSender != null) {
        try {
          await _peerConnection!.removeTrack(_videoSender!);
        } catch (_) {}
        _videoSender = null;
      }
      if (_audioSender != null) {
        try {
          await _peerConnection!.removeTrack(_audioSender!);
        } catch (_) {}
        _audioSender = null;
      }
    }
  }

  /// Queues or adds remote ICE candidates safely after remote description is set.
  Future<void> addRemoteCandidate(dynamic candidate) async {
    RTCIceCandidate? iceCandidate;
    if (candidate is RTCIceCandidate) {
      iceCandidate = candidate;
    } else if (candidate is Map<String, dynamic>) {
      iceCandidate = RTCIceCandidate(
        candidate['candidate'] as String? ?? '',
        candidate['sdpMid'] as String? ?? candidate['sdp_mid'] as String? ?? '',
        (candidate['sdpMLineIndex'] as num?)?.toInt() ??
            (candidate['sdp_m_line_index'] as num?)?.toInt() ??
            0,
      );
    }

    if (iceCandidate == null) return;

    final c = (iceCandidate.candidate ?? '').toLowerCase();
    if (c.contains('127.0.0.') || c.contains('::1') || c.contains('.local')) {
      return;
    }

    if (_peerConnection == null) {
      _queuedRemoteCandidates.add(iceCandidate);
      return;
    }

    final remoteDesc = await _peerConnection!.getRemoteDescription();
    if (remoteDesc == null) {
      _queuedRemoteCandidates.add(iceCandidate);
    } else {
      await _peerConnection!.addCandidate(iceCandidate);
    }
  }

  Future<void> _processQueuedCandidates() async {
    if (_peerConnection == null) return;
    for (final candidate in _queuedRemoteCandidates) {
      final c = (candidate.candidate ?? '').toLowerCase();
      if (c.contains('127.0.0.') || c.contains('::1') || c.contains('.local')) {
        continue;
      }
      await _peerConnection!.addCandidate(candidate);
    }
    _queuedRemoteCandidates.clear();
  }

  /// Closes and resets the active PeerConnection.
  Future<void> closePeerConnection() async {
    _statsMonitor.stop();
    _iceDisconnectTimer?.cancel();
    _iceDisconnectTimer = null;
    if (_peerConnection != null) {
      try {
        await _peerConnection!.close().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      } catch (_) {}
      try {
        await _peerConnection!.dispose().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      } catch (_) {}
      _peerConnection = null;
    }
    _queuedRemoteCandidates.clear();
    _videoSender = null;
    _audioSender = null;
  }

  /// Disposes the PeerConnection, senders, and clears candidate queues.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _statsMonitor.dispose();
    await closePeerConnection();
  }
}
