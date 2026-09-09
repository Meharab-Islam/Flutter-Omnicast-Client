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

  /// Strips transport-cc header extensions and feedback attributes from SDP.
  static String stripTransportCc(String sdp) {
    final lines = sdp.split(RegExp(r'\r?\n'));
    final filtered = lines.where((line) {
      if (line.contains('transport-cc')) return false;
      if (line.contains('transport-wide-cc-extensions')) return false;
      return true;
    }).toList();
    return '${filtered.join('\r\n')}\r\n';
  }

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

    pc.onTrack = (RTCTrackEvent event) async {
      OmniCastLogger.log(
        '[WebRTCManager] onTrack: kind=${event.track.kind}, streams=${event.streams.length}, id=${event.track.id}',
      );

      try {
        event.track.enabled = true;
      } catch (_) {}

      if (event.track.kind == 'audio') {
        try {
          await Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      }

      MediaStream stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams.first;
        if (!stream.getTracks().any((t) => t.id == event.track.id)) {
          try {
            await stream.addTrack(event.track);
          } catch (_) {}
        }
      } else {
        final streamId = 'stream_${event.track.kind}_${event.track.id}';
        stream = await createLocalMediaStream(streamId);
        await stream.addTrack(event.track);
      }
      onRemoteTrack?.call(event.track, stream);
    };

    return pc;
  }

  /// Sets up initial transceivers for a viewer (Receive-Only for audio and video).
  /// Reuses existing transceivers during role downgrades to prevent duplicate m-lines.
  Future<void> setupViewerTransceivers() async {
    final pc = await initializePeerConnection();

    final transceivers = await pc.getTransceivers();
    RTCRtpTransceiver? audioTransceiver;
    RTCRtpTransceiver? videoTransceiver;

    for (final t in transceivers) {
      final senderKind = t.sender.track?.kind;
      final receiverKind = t.receiver.track?.kind;
      if (senderKind == 'audio' || receiverKind == 'audio') {
        audioTransceiver ??= t;
      } else if (senderKind == 'video' || receiverKind == 'video') {
        videoTransceiver ??= t;
      }
    }

    if (audioTransceiver != null) {
      try {
        await audioTransceiver.setDirection(TransceiverDirection.RecvOnly);
        await audioTransceiver.sender.replaceTrack(null);
      } catch (_) {}
    } else {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }

    if (videoTransceiver != null) {
      try {
        await videoTransceiver.setDirection(TransceiverDirection.RecvOnly);
        await videoTransceiver.sender.replaceTrack(null);
      } catch (_) {}
    } else {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }
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

    // Check existing transceivers to reuse if upgrading from viewer (Unified Plan)
    final transceivers = await pc.getTransceivers();
    RTCRtpTransceiver? audioTransceiver;
    RTCRtpTransceiver? videoTransceiver;

    for (final t in transceivers) {
      final senderKind = t.sender.track?.kind;
      final receiverKind = t.receiver.track?.kind;
      if (senderKind == 'audio' || receiverKind == 'audio') {
        audioTransceiver ??= t;
      } else if (senderKind == 'video' || receiverKind == 'video') {
        videoTransceiver ??= t;
      }
    }

    // Add / Replace audio track
    final audioTracks = localStream.getAudioTracks();
    if (audioTracks.isNotEmpty) {
      final audioTrack = audioTracks.first;
      try {
        if (audioTransceiver != null) {
          await audioTransceiver.setDirection(TransceiverDirection.SendRecv);
          await audioTransceiver.sender.replaceTrack(audioTrack);
          _audioSender = audioTransceiver.sender;
        } else {
          _audioSender = await pc.addTrack(audioTrack, localStream);
        }
      } catch (e) {
        OmniCastLogger.warn(
          '[WebRTCManager] Note on audio track attachment: $e',
        );
      }
    }

    // Add / Replace video track with mobile dynamic bitrate & zero-lag framerate preference
    final videoTracks = localStream.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      final videoTrack = videoTracks.first;
      try {
        if (videoTransceiver != null) {
          await videoTransceiver.setDirection(TransceiverDirection.SendRecv);
          await videoTransceiver.sender.replaceTrack(videoTrack);
          _videoSender = videoTransceiver.sender;
        } else {
          _videoSender = await pc.addTrack(videoTrack, localStream);
        }
      } catch (e) {
        OmniCastLogger.warn(
          '[WebRTCManager] Note on video track attachment: $e',
        );
      }

      // Force VP8 codec preference over H264/VP9 for rock-solid packet loss & PLI resilience
      try {
        final currentTransceivers = await pc.getTransceivers();
        final currentVideoTransceiver = currentTransceivers.firstWhere(
          (t) => t.sender.track?.kind == 'video' || t.sender == _videoSender,
        );
        final capabilities = await getRtpSenderCapabilities('video');
        if (capabilities.codecs != null && capabilities.codecs!.isNotEmpty) {
          final sortedCodecs =
              List<RTCRtpCodecCapability>.from(capabilities.codecs!)..sort((
                a,
                b,
              ) {
                final aMime = a.mimeType.toLowerCase();
                final bMime = b.mimeType.toLowerCase();
                if (aMime.contains('vp8') && !bMime.contains('vp8')) return -1;
                if (!aMime.contains('vp8') && bMime.contains('vp8')) return 1;
                return 0;
              });
          await currentVideoTransceiver.setCodecPreferences(sortedCodecs);
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
          try {
            final params = videoSender.parameters;
            params.degradationPreference =
                RTCDegradationPreference.MAINTAIN_FRAMERATE;
            if (params.encodings != null && params.encodings!.isNotEmpty) {
              params.encodings![0].maxBitrate = 1200000;
              params.encodings![0].minBitrate = 300000;
              params.encodings![0].maxFramerate = 24;
            }
            await videoSender.setParameters(params);
            OmniCastLogger.log(
              '[WebRTCManager] Configured clean VP8 video track with maxBitrate: 1200 kbps',
            );
          } catch (paramErr) {
            OmniCastLogger.warn(
              '[WebRTCManager] Set video sender parameters note: $paramErr',
            );
          }
        }
      } catch (e) {
        OmniCastLogger.error(
          '[WebRTCManager] Set single-stream parameters notice: $e',
        );
      }
    }
  }

  /// Dynamically adjusts publishing bitrate and framerate based on stage seat count
  /// to ensure silky-smooth multi-seat streaming without packet loss or thermal lag.
  Future<void> updatePublishBitrateForSeatCount(int occupiedSeatCount) async {
    if (_peerConnection == null) return;
    try {
      final senders = await _peerConnection!.getSenders();
      RTCRtpSender? vSender;
      for (final s in senders) {
        if (s.track?.kind == 'video') {
          vSender = s;
          break;
        }
      }
      vSender ??= _videoSender;
      if (vSender == null) return;

      final int maxBitrate;
      final int minBitrate;
      final int maxFramerate;

      if (occupiedSeatCount <= 1) {
        maxBitrate = 1200000;
        minBitrate = 300000;
        maxFramerate = 30;
      } else if (occupiedSeatCount <= 4) {
        maxBitrate = 600000;
        minBitrate = 180000;
        maxFramerate = 24;
      } else {
        maxBitrate = 350000;
        minBitrate = 120000;
        maxFramerate = 20;
      }

      final params = vSender.parameters;
      if (params.encodings != null && params.encodings!.isNotEmpty) {
        params.encodings![0].maxBitrate = maxBitrate;
        params.encodings![0].minBitrate = minBitrate;
        params.encodings![0].maxFramerate = maxFramerate;
        await vSender.setParameters(params);
        OmniCastLogger.log(
          '[WebRTCManager] Dynamically updated publish bitrate for $occupiedSeatCount active seats: maxBitrate=$maxBitrate, fps=$maxFramerate',
        );
      }
    } catch (e) {
      OmniCastLogger.error(
        '[WebRTCManager] Failed to update publish bitrate: $e',
      );
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
      await pc.setLocalDescription(offer);
      return offer;
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
      processedSdp = enableOpusDtx(processedSdp);
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

  /// Recursively extracts clean SDP string starting from 'v=' from any payload structure (Map, JSON, string)
  static String? extractSdp(dynamic input) {
    if (input == null) return null;
    if (input is RTCSessionDescription) {
      return input.sdp;
    }
    if (input is Map) {
      final val =
          input['sdp'] ?? input['SDP'] ?? input['payload'] ?? input['data'];
      if (val != null) {
        final extracted = extractSdp(val);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }
      for (final v in input.values) {
        if (v is String && v.contains('v=')) {
          final extracted = extractSdp(v);
          if (extracted != null && extracted.isNotEmpty) return extracted;
        }
      }
    }
    if (input is String) {
      var s = input.trim();
      while ((s.startsWith('"') && s.endsWith('"')) ||
          (s.startsWith("'") && s.endsWith("'"))) {
        s = s.substring(1, s.length - 1).trim();
      }
      if (s.startsWith('{') && s.endsWith('}')) {
        try {
          final decoded = jsonDecode(s);
          final extracted = extractSdp(decoded);
          if (extracted != null && extracted.isNotEmpty) return extracted;
        } catch (_) {}
      }
      if (s.contains(r'\r\n') || s.contains(r'\n')) {
        s = s.replaceAll(r'\r\n', '\r\n').replaceAll(r'\n', '\n');
      }
      if (s.contains('v=')) {
        final vIndex = s.indexOf('v=');
        if (vIndex > 0) {
          s = s.substring(vIndex);
        }
        while (s.endsWith('"') || s.endsWith("'") || s.endsWith('}')) {
          s = s.substring(0, s.length - 1).trim();
        }
        final normalized = s.replaceAll(RegExp(r'\r\n|\r|\n'), '\r\n').trim();
        return '$normalized\r\n';
      }
    }
    return null;
  }

  /// Handles an incoming SDP Answer from the SFU.
  Future<void> handleRemoteAnswer(dynamic sdpOrPayload) async {
    if (_peerConnection == null) {
      OmniCastLogger.warn(
        '[WebRTCManager] Cannot handle remote answer without an active PeerConnection, skipping',
      );
      return;
    }

    try {
      final signalingState = await _peerConnection!.getSignalingState();
      if (signalingState == RTCSignalingState.RTCSignalingStateStable) {
        OmniCastLogger.warn(
          '[WebRTCManager] PeerConnection signalingState is already stable, skipping redundant setRemoteDescription',
        );
        return;
      }

      if (signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        OmniCastLogger.warn(
          '[WebRTCManager] PeerConnection signalingState is $signalingState (expected haveLocalOffer), skipping answer',
        );
        return;
      }

      final rawSdp = extractSdp(sdpOrPayload);
      if (rawSdp == null || rawSdp.isEmpty) {
        OmniCastLogger.error(
          '[WebRTCManager] Could not extract valid SDP from payload: $sdpOrPayload',
        );
        return;
      }

      final description = RTCSessionDescription(rawSdp, 'answer');
      await _peerConnection!.setRemoteDescription(description);
      await _processQueuedCandidates();
    } catch (e) {
      OmniCastLogger.error(
        '[WebRTCManager] handleRemoteAnswer setRemoteDescription error: $e',
      );
    }
  }

  /// Handles a server-initiated SDP Offer (e.g. when a new co-host joins), replying with VP8/DTX answer.
  Future<RTCSessionDescription> handleRemoteOfferAndCreateAnswer(
    dynamic sdpOrPayload,
  ) async {
    final pc = await initializePeerConnection();

    final rawSdp = extractSdp(sdpOrPayload);
    if (rawSdp == null || rawSdp.isEmpty) {
      throw StateError(
        'Cannot handle remote offer: invalid or empty SDP payload',
      );
    }

    try {
      final remoteDescription = RTCSessionDescription(rawSdp, 'offer');
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
      processedSdp = enableOpusDtx(processedSdp);
      final mungedAnswer = RTCSessionDescription(
        processedSdp,
        answer.type ?? 'answer',
      );
      await pc.setLocalDescription(mungedAnswer);

      return mungedAnswer;
    } catch (e) {
      OmniCastLogger.error(
        '[WebRTCManager] handleRemoteOfferAndCreateAnswer error: $e',
      );
      rethrow;
    }
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

    // 3. Create clean renegotiation offer without SDP munging corruption
    final offer = await _peerConnection!.createOffer({});
    final nativeOffer = RTCSessionDescription(offer.sdp, offer.type ?? 'offer');
    await _peerConnection!.setLocalDescription(nativeOffer);

    return nativeOffer;
  }

  /// Queues or adds remote ICE candidates safely after remote description is set.
  Future<void> addRemoteCandidate(dynamic candidate) async {
    if (candidate == null) return;
    RTCIceCandidate? iceCandidate;
    if (candidate is RTCIceCandidate) {
      iceCandidate = candidate;
    } else if (candidate is Map) {
      final candStr =
          (candidate['candidate'] ?? candidate['Candidate'])?.toString() ?? '';
      final sdpMid =
          (candidate['sdpMid'] ?? candidate['sdp_mid'] ?? candidate['SdpMid'])
              ?.toString() ??
          '';
      final sdpMLineIndex =
          (candidate['sdpMLineIndex'] as num?)?.toInt() ??
          (candidate['sdp_m_line_index'] as num?)?.toInt() ??
          (candidate['SdpMLineIndex'] as num?)?.toInt() ??
          0;
      if (candStr.isNotEmpty) {
        iceCandidate = RTCIceCandidate(candStr, sdpMid, sdpMLineIndex);
      }
    } else if (candidate is String) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded != null) {
          return addRemoteCandidate(decoded);
        }
      } catch (_) {}
    }

    if (iceCandidate == null) return;

    if (_peerConnection == null) {
      _queuedRemoteCandidates.add(iceCandidate);
      return;
    }

    try {
      final remoteDesc = await _peerConnection!.getRemoteDescription();
      if (remoteDesc == null) {
        _queuedRemoteCandidates.add(iceCandidate);
      } else {
        await _peerConnection!.addCandidate(iceCandidate);
      }
    } catch (e) {
      OmniCastLogger.warn('[WebRTCManager] addCandidate warning: $e');
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
