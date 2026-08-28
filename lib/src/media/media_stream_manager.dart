import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'video_parameters.dart';

/// Manages local media hardware (camera, microphone) and maintains a dynamic
/// registry of [RTCVideoRenderer] instances for local preview and all remote peers.
class MediaStreamManager {
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, MediaStream> _remoteStreams = {};

  VideoParameters _currentParameters = VideoParameters.presetHD720p;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isDisposed = false;

  // Getters
  MediaStream? get localStream => _localStream;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  VideoParameters get currentParameters => _currentParameters;
  Map<String, RTCVideoRenderer> get remoteRenderers =>
      Map.unmodifiable(_remoteRenderers);
  Map<String, MediaStream> get remoteStreams => Map.unmodifiable(_remoteStreams);

  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoMuted => _isVideoMuted;
  bool get hasLocalStream => _localStream != null;

  /// Initializes the local video renderer. Must be called before assigning local streams.
  Future<RTCVideoRenderer> initLocalRenderer() async {
    if (_localRenderer != null) return _localRenderer!;

    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _localRenderer = renderer;
    return renderer;
  }

  /// Opens the device camera and microphone with custom [VideoParameters].
  Future<MediaStream> openUserMedia({
    VideoParameters? parameters,
    bool video = true,
    bool audio = true,
    int? width,
    int? height,
    int? frameRate,
    String? facingMode,
  }) async {
    if (_isDisposed) {
      throw StateError('Cannot open user media on a disposed MediaStreamManager');
    }

    if (parameters != null) {
      _currentParameters = parameters;
    } else if (width != null || height != null || frameRate != null || facingMode != null) {
      _currentParameters = VideoParameters.custom(
        width: width ?? _currentParameters.width,
        height: height ?? _currentParameters.height,
        fps: frameRate ?? _currentParameters.frameRate,
        facingMode: facingMode ?? _currentParameters.facingMode,
      );
    }

    // Stop existing local stream if any
    await stopLocalMedia();

    final mediaConstraints = _currentParameters.toMediaConstraints(
      video: video,
      audio: audio,
    );

    try {
      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;

      // Initialize local renderer if needed and attach stream
      if (_localRenderer == null) {
        await initLocalRenderer();
      }
      _localRenderer!.srcObject = stream;

      _isAudioMuted = !audio;
      _isVideoMuted = !video;

      return stream;
    } catch (e) {
      debugPrint('[MediaStreamManager] Failed to open user media: $e');
      rethrow;
    }
  }

  /// Toggles front/back camera if a video track exists on the local stream.
  Future<void> switchCamera() async {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      await Helper.switchCamera(videoTracks.first);
    }
  }

  /// Enables or disables the local audio track (mic mute/unmute).
  void toggleAudio(bool enabled) {
    if (_localStream == null) return;

    final audioTracks = _localStream!.getAudioTracks();
    for (final track in audioTracks) {
      track.enabled = enabled;
    }
    _isAudioMuted = !enabled;
  }

  /// Enables or disables the local video track (camera mute/unmute).
  void toggleVideo(bool enabled) {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = enabled;
    }
    _isVideoMuted = !enabled;
  }

  /// Retrieves or creates and initializes an [RTCVideoRenderer] for a given [userId].
  Future<RTCVideoRenderer> getOrCreateRemoteRenderer(String userId) async {
    if (_remoteRenderers.containsKey(userId)) {
      return _remoteRenderers[userId]!;
    }

    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[userId] = renderer;

    if (_remoteStreams.containsKey(userId)) {
      renderer.srcObject = _remoteStreams[userId];
    }

    return renderer;
  }

  /// Attaches a remote [MediaStream] to a remote peer's renderer.
  Future<RTCVideoRenderer> attachRemoteStream(
      String userId, MediaStream stream) async {
    _remoteStreams[userId] = stream;
    final renderer = await getOrCreateRemoteRenderer(userId);
    renderer.srcObject = stream;
    return renderer;
  }

  /// Safely removes and disposes the [RTCVideoRenderer] and cached stream for a given [userId].
  Future<void> removeRemoteRenderer(String userId) async {
    final stream = _remoteStreams.remove(userId);
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }

    final renderer = _remoteRenderers.remove(userId);
    if (renderer != null) {
      renderer.srcObject = null;
      await renderer.dispose();
    }
  }

  /// Returns the [RTCVideoRenderer] associated with a given [userId].
  /// Returns [localRenderer] if [userId] is null or 'local'.
  RTCVideoRenderer? getRenderer(String? userId) {
    if (userId == null || userId == 'local') {
      return _localRenderer;
    }
    return _remoteRenderers[userId];
  }

  /// Stops all tracks in the local media stream and clears the local renderer source.
  Future<void> stopLocalMedia() async {
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }
    if (_localRenderer != null) {
      _localRenderer!.srcObject = null;
    }
  }

  /// Permanently disposes all hardware media streams, local renderer, and all remote renderers.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    await stopLocalMedia();

    if (_localRenderer != null) {
      await _localRenderer!.dispose();
      _localRenderer = null;
    }

    final remoteIds = List<String>.from(_remoteRenderers.keys);
    for (final id in remoteIds) {
      await removeRemoteRenderer(id);
    }
    _remoteStreams.clear();
    _remoteRenderers.clear();
  }
}
