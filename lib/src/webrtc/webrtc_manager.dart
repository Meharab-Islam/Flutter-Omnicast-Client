import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_stream_manager.dart';
import '../media/video_parameters.dart';

typedef OnLocalIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnRemoteTrackCallback = void Function(MediaStreamTrack track, MediaStream stream);

/// Manages [RTCPeerConnection] lifecycle, SDP offer/answer negotiations,
/// dynamic transceivers, ICE exchange, simulcast encodings, and Dynacast layer control.
class WebRTCManager {
  final MediaStreamManager mediaStreamManager;
  final Map<String, dynamic> rtcConfiguration;

  RTCPeerConnection? _peerConnection;
  RTCRtpSender? _videoSender;
  RTCRtpSender? _audioSender;

  bool _isDisposed = false;
  bool _isNegotiating = false;
  bool _simulcastEnabled = false;
  final List<RTCIceCandidate> _queuedRemoteCandidates = [];

  // Callbacks
  OnLocalIceCandidateCallback? onLocalIceCandidate;
  OnRemoteTrackCallback? onRemoteTrack;

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

  /// Adds local media tracks to [RTCPeerConnection], optionally configuring Simulcast encodings.
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

    // Add video track with Simulcast or Single encoding
    final videoTracks = localStream.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      final videoTrack = videoTracks.first;

      if (enableSimulcast) {
        // Multi-layer simulcast transceivers: 'f' (full), 'h' (half), 'q' (quarter)
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
                maxBitrate: 2500000,
                maxFramerate: 30,
              ),
              RTCRtpEncoding(
                rid: 'h',
                active: true,
                scaleResolutionDownBy: 2.0,
                maxBitrate: 800000,
                maxFramerate: 30,
              ),
              RTCRtpEncoding(
                rid: 'q',
                active: true,
                scaleResolutionDownBy: 4.0,
                maxBitrate: 250000,
                maxFramerate: 15,
              ),
            ],
          ),
        );
        _videoSender = transceiver.sender;
      } else {
        // Standard single high-quality encoding
        _videoSender = await pc.addTrack(videoTrack, localStream);
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

  /// Creates an SDP Offer and sets it as the local description.
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

  /// Handles an incoming SDP Answer from the SFU.
  Future<void> handleRemoteAnswer(String sdp) async {
    if (_peerConnection == null) {
      throw StateError('Cannot handle remote answer without an active PeerConnection');
    }

    final description = RTCSessionDescription(sdp, 'answer');
    await _peerConnection!.setRemoteDescription(description);
    await _processQueuedCandidates();
  }

  /// Handles a server-initiated SDP Offer (e.g. when a new co-host joins).
  Future<RTCSessionDescription> handleRemoteOfferAndCreateAnswer(String sdp) async {
    final pc = await initializePeerConnection();

    final remoteDescription = RTCSessionDescription(sdp, 'offer');
    await pc.setRemoteDescription(remoteDescription);
    await _processQueuedCandidates();

    final answer = await pc.createAnswer({});
    await pc.setLocalDescription(answer);

    return answer;
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

    // 3. Create renegotiation offer
    return await createAndSetLocalOffer();
  }

  /// Handles incoming remote ICE candidate.
  Future<void> addRemoteCandidate(Map<String, dynamic> candidateMap) async {
    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String? ?? candidateMap['sdp'] as String?,
      candidateMap['sdpMid'] as String?,
      candidateMap['sdpMLineIndex'] as int?,
    );

    if (_peerConnection == null ||
        await _peerConnection!.getRemoteDescription() == null) {
      _queuedRemoteCandidates.add(candidate);
      return;
    }

    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('[WebRTCManager] Failed to add ICE candidate: $e');
    }
  }

  Future<void> _processQueuedCandidates() async {
    if (_peerConnection == null) return;
    final candidates = List<RTCIceCandidate>.from(_queuedRemoteCandidates);
    _queuedRemoteCandidates.clear();

    for (final candidate in candidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('[WebRTCManager] Failed to add queued ICE candidate: $e');
      }
    }
  }

  /// Closes and cleans up the active [RTCPeerConnection].
  Future<void> closePeerConnection() async {
    _queuedRemoteCandidates.clear();
    _videoSender = null;
    _audioSender = null;
    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }
  }

  /// Permanently disposes the [WebRTCManager].
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await closePeerConnection();
  }
}
