import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_stream_manager.dart';

typedef OnLocalIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnRemoteTrackCallback = void Function(MediaStreamTrack track, MediaStream stream);

/// Manages [RTCPeerConnection] lifecycle, SDP offer/answer negotiations,
/// dynamic transceivers, ICE exchange, and seamless renegotiation for OmniCast.
class WebRTCManager {
  final MediaStreamManager mediaStreamManager;
  final Map<String, dynamic> rtcConfiguration;

  RTCPeerConnection? _peerConnection;
  bool _isDisposed = false;
  bool _isNegotiating = false;
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

  /// Adds local media tracks from [MediaStreamManager] to the [RTCPeerConnection].
  Future<void> addLocalMediaTracks() async {
    final pc = await initializePeerConnection();
    final localStream = mediaStreamManager.localStream;
    if (localStream == null) {
      throw StateError('Cannot add local media tracks: localStream is null');
    }

    for (final track in localStream.getTracks()) {
      await pc.addTrack(track, localStream);
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
  ///
  /// Sets remote description, creates answer, sets local description, and returns the answer.
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
  ///
  /// Opens local hardware media, adds tracks to the existing peer connection,
  /// and creates a new renegotiation offer.
  Future<RTCSessionDescription> upgradeViewerToCoHost({
    bool video = true,
    bool audio = true,
  }) async {
    if (_peerConnection == null) {
      throw StateError('Cannot upgrade to co-host without an active PeerConnection');
    }

    // 1. Capture local camera/microphone
    await mediaStreamManager.openUserMedia(video: video, audio: audio);

    // 2. Add local tracks to existing PeerConnection
    await addLocalMediaTracks();

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
