import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_stream_manager.dart';
import '../media/video_parameters.dart';
import 'webrtc_stats_monitor.dart';

typedef OnLocalIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnRemoteTrackCallback = void Function(MediaStreamTrack track, MediaStream stream);
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
  })  : rtcConfiguration = configuration ??
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

  /// Modifies an SDP string to prioritize a specific codec (e.g. 'H264') at the front of the m=video line.
  /// Prioritizes H.264 Hardware Baseline profile to eliminate mobile CPU lag and macroblocking artifacts.
  static String preferCodec(String sdp, String codec) {
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
        (l) => l.toLowerCase().startsWith('a=rtpmap:$pt ${codec.toLowerCase()}'),
        orElse: () => '',
      );
      if (rtpmap.isNotEmpty) {
        codecPayloads.add(pt);
      } else {
        otherPayloads.add(pt);
      }
    }

    if (codecPayloads.isEmpty) return sdp;

    lines[mVideoIndex] = '${header.join(' ')} ${codecPayloads.join(' ')} ${otherPayloads.join(' ')}';
    return lines.join(delimiter);
  }

  /// Injects initial starting bitrate (500 kbps) and max bitrate constraints directly into SDP
  /// to eliminate the initial bandwidth burst and allow smooth TWCC ramp-up.
  static String setInitialBitrate(String sdp, {int startKbps = 500, int minKbps = 150, int maxKbps = 800}) {
    final delimiter = sdp.contains('\r\n') ? '\r\n' : '\n';
    final lines = sdp.split(delimiter);
    final mVideoIndex = lines.indexWhere((l) => l.startsWith('m=video'));
    if (mVideoIndex == -1) return sdp;

    // 1. Insert b=AS / b=TIAS under m=video line
    final newLines = <String>[];
    for (var i = 0; i < lines.length; i++) {
      newLines.add(lines[i]);
      if (i == mVideoIndex) {
        newLines.add('b=AS:$startKbps');
        newLines.add('b=TIAS:${startKbps * 1000}');
      }
    }

    // 2. Append x-google bitrates to video fmtp lines
    for (var i = 0; i < newLines.length; i++) {
      final line = newLines[i];
      if (line.startsWith('a=fmtp:')) {
        if (!line.contains('x-google-start-bitrate=')) {
          newLines[i] = '$line;x-google-start-bitrate=$startKbps;x-google-min-bitrate=$minKbps;x-google-max-bitrate=$maxKbps';
        }
      }
    }

    return newLines.join(delimiter);
  }

  /// Modifies an SDP string to enable Opus DTX (Discontinuous Transmission) and FEC (Forward Error Correction).
  /// Saves significant bandwidth and battery when the broadcaster/guest is silent.
  static String enableOpusDtx(String sdp) {
    final delimiter = sdp.contains('\r\n') ? '\r\n' : '\n';
    final lines = sdp.split(delimiter);
    final opusPayloadTypes = <String>[];

    for (final line in lines) {
      if (line.toLowerCase().contains('opus/48000')) {
        final match = RegExp(r'a=rtpmap:(\d+)\s+opus', caseSensitive: false).firstMatch(line);
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

  /// Initializes a new [RTCPeerConnection] with standard configuration and sets up listeners.
  Future<RTCPeerConnection> initializePeerConnection() async {
    if (_peerConnection != null) {
      return _peerConnection!;
    }

    final pc = await createPeerConnection(rtcConfiguration);
    _peerConnection = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        onLocalIceCandidate?.call(candidate);
      }
    };

    pc.onIceConnectionState = (state) {
      debugPrint('[WebRTCManager] ICE Connection State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _iceDisconnectTimer?.cancel();
        // 1-2s seamless ICE restart window during WiFi <-> Cellular handoffs
        _iceDisconnectTimer = Timer(const Duration(milliseconds: 1500), () {
          debugPrint('[WebRTCManager] ICE disconnected for >1.5s -> Triggering seamless ICE Restart');
          onIceRestartNeeded?.call();
        });
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = null;
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = null;
        debugPrint('[WebRTCManager] ICE Failed -> Triggering Immediate ICE Restart');
        onIceRestartNeeded?.call();
      }
    };

    pc.onConnectionState = (state) {
      debugPrint('[WebRTCManager] PeerConnection State: $state');
    };

    pc.onTrack = (RTCTrackEvent event) {
      debugPrint(
          '[WebRTCManager] onTrack: kind=${event.track.kind}, streams=${event.streams.length}, id=${event.track.id}');

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
      }
    };

    return pc;
  }

  /// Sets up initial transceivers for a viewer (Receive-Only for audio and video).
  Future<void> setupViewerTransceivers() async {
    final pc = await initializePeerConnection();

    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(
        direction: TransceiverDirection.RecvOnly,
      ),
    );

    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(
        direction: TransceiverDirection.RecvOnly,
      ),
    );
  }

  /// Adds local media tracks to [RTCPeerConnection], configuring hardware-friendly H264/VP8 codecs,
  /// dynamic bitrate adaptation (1000-1200 kbps max), and maintain-framerate degradation preference for zero lag.
  Future<void> addLocalMediaTracks({bool enableSimulcast = true}) async {
    final pc = await initializePeerConnection();
    final localStream = mediaStreamManager.localStream;
    if (localStream == null) {
      throw StateError('Cannot add local media tracks: localStream is null');
    }

    _simulcastEnabled = enableSimulcast;

    // Add audio track
    final audioTracks = localStream.getAudioTracks();
    if (audioTracks.isNotEmpty) {
      _audioSender = await pc.addTrack(audioTracks.first, localStream);
    }

    // Add video track with mobile dynamic bitrate & zero-lag framerate preference
    final videoTracks = localStream.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      final videoTrack = videoTracks.first;

      if (enableSimulcast) {
        // Multi-layer simulcast/SVC transceivers: 'f' (smooth 720p/480p @ 1100 kbps), 'h' (half @ 450 kbps), 'q' (quarter @ 180 kbps)
        final transceiver = await pc.addTransceiver(
          track: videoTrack,
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.SendRecv,
            streams: [localStream],
            sendEncodings: [
              // High Layer (Full Resolution) - 600 Kbps max, 24fps
              RTCRtpEncoding(
                rid: 'f',
                active: true,
                scaleResolutionDownBy: 1.0,
                maxBitrate: 600000,
                maxFramerate: 24,
              ),
              // Medium Layer (Half Resolution) - 250 Kbps max, 20fps
              RTCRtpEncoding(
                rid: 'h',
                active: true,
                scaleResolutionDownBy: 2.0,
                maxBitrate: 250000,
                maxFramerate: 20,
              ),
              // Low Layer (Quarter Resolution) - 100 Kbps max, 15fps
              RTCRtpEncoding(
                rid: 'q',
                active: true,
                scaleResolutionDownBy: 4.0,
                maxBitrate: 100000,
                maxFramerate: 15,
              ),
            ],
          ),
        );
        _videoSender = transceiver.sender;

        // Force H264 hardware-accelerated codec preference over VP8 to fix Android artifacts
        try {
          final capabilities = await getRtpSenderCapabilities('video');
          if (capabilities.codecs != null && capabilities.codecs!.isNotEmpty) {
            final sortedCodecs = List<RTCRtpCodecCapability>.from(capabilities.codecs!);
            sortedCodecs.sort((a, b) {
              final mimeA = a.mimeType.toLowerCase();
              final mimeB = b.mimeType.toLowerCase();
              int scoreA = mimeA.contains('h264') ? 0 : (mimeA.contains('vp8') ? 1 : 2);
              int scoreB = mimeB.contains('h264') ? 0 : (mimeB.contains('vp8') ? 1 : 2);
              return scoreA.compareTo(scoreB);
            });
            await transceiver.setCodecPreferences(sortedCodecs);
          }
        } catch (_) {}

        // Apply maintain-framerate degradation preference and enforce maxBitrate on sender
        try {
          final senders = await pc.getSenders();
          final videoSender = senders.firstWhere(
            (s) => s.track?.kind == 'video',
            orElse: () => _videoSender ?? senders.first,
          );
          final params = videoSender.parameters;
          params.degradationPreference = RTCDegradationPreference.MAINTAIN_FRAMERATE;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            params.encodings![0].maxBitrate = 500000;
          }
          await videoSender.setParameters(params);
        } catch (e) {
          debugPrint('[WebRTCManager] Set degradationPreference notice: $e');
        }
      } else {
        // Standard single stream with maintain-framerate degradation and 500 kbps strict ceiling
        _videoSender = await pc.addTrack(videoTrack, localStream);
        try {
          final senders = await pc.getSenders();
          final videoSender = senders.firstWhere(
            (s) => s.track?.kind == 'video',
            orElse: () => _videoSender ?? senders.first,
          );
          final params = videoSender.parameters;
          params.degradationPreference = RTCDegradationPreference.MAINTAIN_FRAMERATE;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            params.encodings![0].maxBitrate = 500000;
            params.encodings![0].minBitrate = 150000;
            params.encodings![0].maxFramerate = 24;
            params.encodings![0].scalabilityMode = 'L1T3';
          }
          await videoSender.setParameters(params);
        } catch (e) {
          debugPrint('[WebRTCManager] Set single-stream parameters notice: $e');
        }
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
          debugPrint('[WebRTCManager Dynacast] Set layer $rid active=$active');
        }
      }

      if (updated) {
        await _videoSender!.setParameters(params);
      }
    } catch (e) {
      debugPrint('[WebRTCManager Dynacast] Error setting layer active: $e');
    }
  }

  /// Strictly enforces maximum video bitrate limit on the video RTCRtpSender to prevent macroblocking and congestion.
  Future<void> enforceMaxVideoBitrate({int maxBitrate = 500000}) async {
    if (_peerConnection == null) return;
    try {
      final senders = await _peerConnection!.getSenders();
      final videoSenders = senders.where((s) => s.track?.kind == 'video' || s == _videoSender);
      for (final sender in videoSenders) {
        final parameters = sender.parameters;
        if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
          for (final encoding in parameters.encodings!) {
            encoding.maxBitrate = maxBitrate;
            if (encoding.minBitrate != null && encoding.minBitrate! > maxBitrate) {
              encoding.minBitrate = maxBitrate ~/ 2;
            }
          }
          parameters.degradationPreference = RTCDegradationPreference.MAINTAIN_FRAMERATE;
          await sender.setParameters(parameters);
          debugPrint('[WebRTCManager] Enforced maxVideoBitrate: $maxBitrate bps on sender');
        }
      }
    } catch (e) {
      debugPrint('[WebRTCManager] Error enforcing max video bitrate: $e');
    }
  }

  /// Creates an SDP Offer, prioritizes H264 codec, disables VAD, and sets initial bitrate.
  Future<RTCSessionDescription> createAndSetLocalOffer({
    bool offerToReceiveAudio = true,
    bool offerToReceiveVideo = true,
  }) async {
    final pc = await initializePeerConnection();

    final constraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': offerToReceiveAudio,
        'OfferToReceiveVideo': offerToReceiveVideo,
        'voiceActivityDetection': false,
      },
      'optional': [
        {'VoiceActivityDetection': false},
      ],
    };

    _isNegotiating = true;
    try {
      final offer = await pc.createOffer(constraints);
      var processedSdp = preferCodec(offer.sdp ?? '', 'H264');
      processedSdp = setInitialBitrate(processedSdp, startKbps: 500, minKbps: 150, maxKbps: 800);
      processedSdp = enableOpusDtx(processedSdp);
      final mungedOffer = RTCSessionDescription(processedSdp, offer.type);
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
        'voiceActivityDetection': false,
      },
      'optional': [
        {'VoiceActivityDetection': false},
      ],
    };

    _isNegotiating = true;
    try {
      final offer = await pc.createOffer(constraints);
      var processedSdp = preferCodec(offer.sdp ?? '', 'H264');
      processedSdp = setInitialBitrate(processedSdp, startKbps: 500, minKbps: 150, maxKbps: 800);
      processedSdp = enableOpusDtx(processedSdp);
      final mungedOffer = RTCSessionDescription(processedSdp, offer.type);
      await pc.setLocalDescription(mungedOffer);
      return mungedOffer;
    } finally {
      _isNegotiating = false;
    }
  }

  /// Handles an incoming SDP Answer from the SFU.
  Future<void> handleRemoteAnswer(String sdp) async {
    if (_peerConnection == null) {
      throw StateError('Cannot handle remote answer without an active PeerConnection');
    }

    final description = RTCSessionDescription(sdp, 'answer');
    await _peerConnection!.setRemoteDescription(description);
    await _processQueuedCandidates();
  }

  /// Handles a server-initiated SDP Offer (e.g. when a new co-host joins), replying with H264/DTX answer.
  Future<RTCSessionDescription> handleRemoteOfferAndCreateAnswer(String sdp) async {
    final pc = await initializePeerConnection();

    final remoteDescription = RTCSessionDescription(sdp, 'offer');
    await pc.setRemoteDescription(remoteDescription);
    await _processQueuedCandidates();

    final answer = await pc.createAnswer({
      'mandatory': {
        'voiceActivityDetection': false,
      },
    });
    var processedSdp = preferCodec(answer.sdp ?? '', 'H264');
    processedSdp = setInitialBitrate(processedSdp, startKbps: 500, minKbps: 150, maxKbps: 800);
    processedSdp = enableOpusDtx(processedSdp);
    final mungedAnswer = RTCSessionDescription(processedSdp, answer.type);
    await pc.setLocalDescription(mungedAnswer);

    return mungedAnswer;
  }

  /// Seamlessly upgrades a Viewer to a Co-Host without tearing down the existing [RTCPeerConnection].
  Future<RTCSessionDescription> upgradeViewerToCoHost({
    bool video = true,
    bool audio = true,
    bool enableSimulcast = true,
    VideoParameters? parameters,
  }) async {
    if (_peerConnection == null) {
      throw StateError('Cannot upgrade to co-host without an active PeerConnection');
    }

    // 1. Capture local camera/microphone
    await mediaStreamManager.openUserMedia(
      parameters: parameters,
      video: video,
      audio: audio,
    );

    // 2. Add local tracks to existing PeerConnection with simulcast option
    await addLocalMediaTracks(enableSimulcast: enableSimulcast);

    // 3. Create renegotiation offer with H264 and Opus DTX preference
    final offer = await _peerConnection!.createOffer({
      'mandatory': {
        'voiceActivityDetection': false,
      },
    });
    var processedSdp = preferCodec(offer.sdp ?? '', 'H264');
    processedSdp = setInitialBitrate(processedSdp, startKbps: 500, minKbps: 150, maxKbps: 800);
    processedSdp = enableOpusDtx(processedSdp);
    final mungedOffer = RTCSessionDescription(processedSdp, offer.type);
    await _peerConnection!.setLocalDescription(mungedOffer);

    return mungedOffer;
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
        await _peerConnection!.close().timeout(const Duration(milliseconds: 250), onTimeout: () {});
      } catch (_) {}
      try {
        await _peerConnection!.dispose().timeout(const Duration(milliseconds: 250), onTimeout: () {});
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
