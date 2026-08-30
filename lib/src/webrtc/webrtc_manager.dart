import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_stream_manager.dart';
import '../media/video_parameters.dart';

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

  final List<RTCIceCandidate> _queuedRemoteCandidates = [];

  // Callbacks
  OnLocalIceCandidateCallback? onLocalIceCandidate;
  OnRemoteTrackCallback? onRemoteTrack;
  OnIceRestartNeededCallback? onIceRestartNeeded;

  WebRTCManager({
    required this.mediaStreamManager,
    Map<String, dynamic>? configuration,
  }) : rtcConfiguration = configuration ??
            {
              'iceServers': [
                {'urls': 'stun:stun.l.google.com:19302'},
                {'urls': 'stun:stun1.l.google.com:19302'},
              ],
              'sdpSemantics': 'unified-plan',
            };

  RTCPeerConnection? get peerConnection => _peerConnection;
  bool get hasPeerConnection => _peerConnection != null;
  bool get isNegotiating => _isNegotiating;
  bool get simulcastEnabled => _simulcastEnabled;
  RTCRtpSender? get videoSender => _videoSender;
  RTCRtpSender? get audioSender => _audioSender;

  /// Modifies an SDP string to prioritize a specific codec (e.g. 'VP8') at the front of the m=video line.
  /// Eliminates Android hardware H.264 green/pink screen artifacts and packet loss decoder freezes.
  static String preferCodec(String sdp, String codec) {
    final lines = sdp.split('\r\n');
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
    return lines.join('\r\n');
  }

  /// Modifies an SDP string to enable Opus DTX (Discontinuous Transmission) and FEC (Forward Error Correction).
  /// Saves significant bandwidth and battery when the broadcaster/guest is silent.
  static String enableOpusDtx(String sdp) {
    final lines = sdp.split('\r\n');
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

    return lines.join('\r\n');
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
        _iceDisconnectTimer = Timer(const Duration(seconds: 3), () {
          debugPrint('[WebRTCManager] ICE disconnected for >3s -> Triggering ICE Restart');
          onIceRestartNeeded?.call();
        });
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _iceDisconnectTimer?.cancel();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _iceDisconnectTimer?.cancel();
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
              RTCRtpEncoding(
                rid: 'f',
                active: true,
                scaleResolutionDownBy: 1.0,
                maxBitrate: 1100000, // 1100 kbps dynamic ceiling (prevents network choking & packet queue lag)
                minBitrate: 350000,  // 350 kbps floor
                maxFramerate: 30,
                scalabilityMode: 'L1T3',
              ),
              RTCRtpEncoding(
                rid: 'h',
                active: true,
                scaleResolutionDownBy: 2.0,
                maxBitrate: 450000, // 450 kbps for half resolution
                minBitrate: 150000,
                maxFramerate: 24,
                scalabilityMode: 'L1T3',
              ),
              RTCRtpEncoding(
                rid: 'q',
                active: true,
                scaleResolutionDownBy: 4.0,
                maxBitrate: 180000, // 180 kbps for quarter resolution
                minBitrate: 60000,
                maxFramerate: 15,
                scalabilityMode: 'L1T3',
              ),
            ],
          ),
        );
        _videoSender = transceiver.sender;

        // Prefer hardware-accelerated codecs (H264 Baseline Profile / VP8)
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

        // Apply maintain-framerate degradation preference to prevent freezing
        try {
          final params = _videoSender!.parameters;
          params.degradationPreference = RTCDegradationPreference.MAINTAIN_FRAMERATE;
          await _videoSender!.setParameters(params);
        } catch (e) {
          debugPrint('[WebRTCManager] Set degradationPreference notice: $e');
        }
      } else {
        // Standard single stream with maintain-framerate degradation and 1100 kbps dynamic ceiling
        _videoSender = await pc.addTrack(videoTrack, localStream);
        try {
          final params = _videoSender!.parameters;
          params.degradationPreference = RTCDegradationPreference.MAINTAIN_FRAMERATE;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            params.encodings!.first.maxBitrate = 1100000;
            params.encodings!.first.minBitrate = 350000;
            params.encodings!.first.maxFramerate = 30;
            params.encodings!.first.scalabilityMode = 'L1T3';
          }
          await _videoSender!.setParameters(params);
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

  /// Creates an SDP Offer, prioritizes VP8 codec, and sets it as the local description.
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
      },
      'optional': [],
    };

    _isNegotiating = true;
    try {
      final offer = await pc.createOffer(constraints);
      var processedSdp = preferCodec(offer.sdp ?? '', 'VP8');
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

  /// Handles a server-initiated SDP Offer (e.g. when a new co-host joins), replying with VP8/DTX answer.
  Future<RTCSessionDescription> handleRemoteOfferAndCreateAnswer(String sdp) async {
    final pc = await initializePeerConnection();

    final remoteDescription = RTCSessionDescription(sdp, 'offer');
    await pc.setRemoteDescription(remoteDescription);
    await _processQueuedCandidates();

    final answer = await pc.createAnswer({});
    var processedSdp = preferCodec(answer.sdp ?? '', 'VP8');
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

    // 3. Create renegotiation offer with VP8 and Opus DTX preference
    final offer = await _peerConnection!.createOffer();
    var processedSdp = preferCodec(offer.sdp ?? '', 'VP8');
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
    _iceDisconnectTimer?.cancel();
    _iceDisconnectTimer = null;
    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
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

    await closePeerConnection();
  }
}
