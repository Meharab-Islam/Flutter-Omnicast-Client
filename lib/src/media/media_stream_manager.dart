import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'video_parameters.dart';
import '../utils/omnicast_logger.dart';

/// Manages local media hardware (camera, microphone) and maintains a dynamic
/// registry of [RTCVideoRenderer] instances for local preview and all remote peers.
class MediaStreamManager implements Listenable {
  final ValueNotifier<int> _changeNotifier = ValueNotifier<int>(0);

  @override
  void addListener(VoidCallback listener) =>
      _changeNotifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _changeNotifier.removeListener(listener);

  void notifyListeners() {
    if (!_isDisposed) {
      _changeNotifier.value++;
    }
  }

  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, MediaStream> _remoteStreams = {};

  VideoParameters _currentParameters = VideoParameters.presetSmooth480p;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isDisposed = false;

  // Getters
  MediaStream? get localStream => _localStream;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  VideoParameters get currentParameters => _currentParameters;
  Map<String, RTCVideoRenderer> get remoteRenderers =>
      Map.unmodifiable(_remoteRenderers);
  Map<String, MediaStream> get remoteStreams =>
      Map.unmodifiable(_remoteStreams);

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
      throw StateError(
        'Cannot open user media on a disposed MediaStreamManager',
      );
    }

    if (parameters != null) {
      _currentParameters = parameters;
    } else if (width != null ||
        height != null ||
        frameRate != null ||
        facingMode != null) {
      _currentParameters = VideoParameters.custom(
        width: width ?? _currentParameters.width,
        height: height ?? _currentParameters.height,
        fps: frameRate ?? _currentParameters.frameRate,
        facingMode: facingMode ?? _currentParameters.facingMode,
      );
    }

    // Stop existing local stream if any
    await stopLocalMedia();

    // Request permissions proactively if needed
    try {
      if (video) {
        await Permission.camera.request();
      }
      if (audio) {
        await Permission.microphone.request();
      }
    } catch (_) {}

    final mediaConstraints = _currentParameters.toMediaConstraints(
      video: video,
      audio: audio,
    );

    MediaStream stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      OmniCastLogger.error(
        '[MediaStreamManager] Primary getUserMedia failed ($e), attempting baseline fallback constraints',
      );
      try {
        stream = await navigator.mediaDevices.getUserMedia({
          'audio': audio,
          'video': video
              ? {'facingMode': _currentParameters.facingMode}
              : false,
        });
      } catch (fallbackError) {
        OmniCastLogger.error(
          '[MediaStreamManager] Fallback getUserMedia failed: $fallbackError',
        );
        rethrow;
      }
    }

    _localStream = stream;

    // Initialize local renderer if needed and attach stream
    if (_localRenderer == null) {
      await initLocalRenderer();
    }
    _localRenderer!.srcObject = stream;

    _isAudioMuted = !audio;
    _isVideoMuted = !video;

    return stream;
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

  /// Explicitly mutes or unmutes a remote peer's media track by kind ('audio' or 'video').
  void setRemoteTrackEnabled(String? userId, String kind, bool enabled) {
    if (userId == null || userId.isEmpty) {
      return;
    }

    // 1. Try exact match
    MediaStream? stream = _remoteStreams[userId];

    // 2. Try partial match (streamId vs userId)
    if (stream == null) {
      for (final entry in _remoteStreams.entries) {
        if (entry.key.contains(userId) || userId.contains(entry.key)) {
          stream = entry.value;
          break;
        }
      }
    }

    if (stream != null) {
      if (kind == 'audio') {
        for (final track in stream.getAudioTracks()) {
          track.enabled = enabled;
        }
      } else if (kind == 'video') {
        for (final track in stream.getVideoTracks()) {
          track.enabled = enabled;
        }
      }
    }
  }

  /// Registers an alias for an existing remote user/stream to avoid allocating duplicate renderers.
  void registerAlias(String alias, String targetUserId) {
    if (alias == targetUserId) return;
    if (_remoteStreams.containsKey(targetUserId)) {
      _remoteStreams[alias] = _remoteStreams[targetUserId]!;
    }
    if (_remoteRenderers.containsKey(targetUserId)) {
      _remoteRenderers[alias] = _remoteRenderers[targetUserId]!;
    }
  }

  /// Retrieves or creates and initializes an [RTCVideoRenderer] for a given [userId].
  /// Reuses any existing renderer attached to the same [MediaStream] to prevent EGL context exhaustion.
  Future<RTCVideoRenderer> getOrCreateRemoteRenderer(String userId) async {
    if (_remoteRenderers.containsKey(userId)) {
      return _remoteRenderers[userId]!;
    }

    final targetStream = _remoteStreams[userId];
    if (targetStream != null) {
      for (final entry in _remoteRenderers.entries) {
        if (entry.value.srcObject == targetStream) {
          _remoteRenderers[userId] = entry.value;
          return entry.value;
        }
      }
    }

    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[userId] = renderer;

    if (targetStream != null) {
      renderer.srcObject = targetStream;
    }

    return renderer;
  }

  /// Attaches a remote [MediaStream] to a remote peer's renderer.
  /// Merges incoming audio/video tracks into any existing stream for [userId]
  /// and ensures audio tracks do not clobber active video rendering.
  Future<RTCVideoRenderer> attachRemoteStream(
    String userId,
    MediaStream stream,
  ) async {
    final existingStream = _remoteStreams[userId];
    if (existingStream != null && existingStream != stream) {
      for (final track in stream.getTracks()) {
        final hasTrack = existingStream.getTracks().any(
          (t) => t.id == track.id,
        );
        if (!hasTrack) {
          try {
            existingStream.addTrack(track);
          } catch (e) {
            OmniCastLogger.log(
              '[MediaStreamManager] addTrack failed ($e), falling back to replacing stream',
            );
            _remoteStreams[userId] = stream;
            break;
          }
        }
      }
    } else {
      _remoteStreams[userId] = stream;
    }

    final renderer = await getOrCreateRemoteRenderer(userId);
    final activeStream = _remoteStreams[userId]!;

    // Only overwrite renderer.srcObject if activeStream has video tracks,
    // or if renderer currently has no srcObject. This ensures incoming audio tracks
    // never wipe out active video rendering!
    if (activeStream.getVideoTracks().isNotEmpty ||
        renderer.srcObject == null) {
      renderer.srcObject = activeStream;
    }

    if (!_isDisposed) {
      notifyListeners();
    }
    return renderer;
  }

  /// Safely removes and disposes the [RTCVideoRenderer] and cached stream for a given [userId].
  /// Does not prematurely dispose renderers that are still shared with aliases.
  Future<void> removeRemoteRenderer(String userId) async {
    final stream = _remoteStreams.remove(userId);
    if (stream != null && !_remoteStreams.values.contains(stream)) {
      for (final track in stream.getTracks()) {
        try {
          await track.stop();
        } catch (_) {}
      }
      try {
        await stream.dispose();
      } catch (_) {}
    }

    final renderer = _remoteRenderers.remove(userId);
    if (renderer != null) {
      final isShared = _remoteRenderers.values.contains(renderer);
      if (!isShared) {
        renderer.srcObject = null;
        try {
          await renderer.dispose().timeout(
            const Duration(milliseconds: 250),
            onTimeout: () {},
          );
        } catch (_) {}
      }
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Returns the [RTCVideoRenderer] associated with a given [userId].
  /// Returns [localRenderer] if [userId] is null or 'local'.
  RTCVideoRenderer? getRenderer(String? userId) {
    if (userId == null || userId == 'local') {
      return _localRenderer;
    }
    if (_remoteRenderers.containsKey(userId)) {
      return _remoteRenderers[userId];
    }
    // Match partial user IDs or stream IDs
    for (final entry in _remoteRenderers.entries) {
      if (entry.key.contains(userId) || userId.contains(entry.key)) {
        return entry.value;
      }
    }
    // Fallback for live broadcast viewers: looking up 'host' specifically
    if (userId == 'host' && _remoteRenderers.isNotEmpty) {
      return _remoteRenderers['host'] ?? _remoteRenderers.values.first;
    }
    return null;
  }

  /// Stops all tracks in the local media stream and clears the local renderer source.
  Future<void> stopLocalMedia() async {
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        try {
          await track.stop().timeout(
            const Duration(milliseconds: 250),
            onTimeout: () {},
          );
        } catch (_) {}
      }
      try {
        await _localStream!.dispose().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      } catch (_) {}
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
      try {
        await _localRenderer!.dispose().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      } catch (_) {}
      _localRenderer = null;
    }

    final uniqueStreams = _remoteStreams.values.toSet();
    for (final stream in uniqueStreams) {
      for (final track in stream.getTracks()) {
        try {
          await track.stop();
        } catch (_) {}
      }
      try {
        await stream.dispose();
      } catch (_) {}
    }
    _remoteStreams.clear();

    final uniqueRenderers = _remoteRenderers.values.toSet();
    for (final renderer in uniqueRenderers) {
      renderer.srcObject = null;
      try {
        await renderer.dispose().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      } catch (_) {}
    }
    _remoteRenderers.clear();
    _changeNotifier.dispose();
  }
}
