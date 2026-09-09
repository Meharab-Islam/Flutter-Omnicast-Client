import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'video_parameters.dart';
import '../utils/omnicast_logger.dart';

/// Manages local media hardware (camera, microphone) and maintains a dynamic
/// registry of [RTCVideoRenderer] instances for local preview and all remote peers.
class MediaStreamManager with ChangeNotifier {
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, String> _aliases = {};

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

  /// Registers an alias for a user ID (e.g. mapping 'host' to a specific user ID).
  void registerAlias(String alias, String targetId) {
    _aliases[alias] = targetId;
  }

  /// Resolves an alias or canonical user ID (e.g. mapping alias to target user ID).
  String resolveUserId(String userId) => _aliases[userId] ?? userId;

  /// Initializes the local video renderer safely without leaking EGL contexts.
  Future<RTCVideoRenderer?> initLocalRenderer() async {
    if (_localRenderer != null) return _localRenderer!;

    final renderer = RTCVideoRenderer();
    try {
      await renderer.initialize();
      _localRenderer = renderer;
      if (_localStream != null) {
        renderer.srcObject = _localStream;
      }
    } catch (e) {
      OmniCastLogger.warn(
        '[MediaStreamManager] initLocalRenderer failed to allocate EGL context: $e',
      );
      return null;
    }
    notifyListeners();
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

    // Attach stream to existing local renderer if active without creating redundant EGL contexts
    if (_localRenderer != null) {
      _localRenderer!.srcObject = stream;
    }

    _isAudioMuted = !audio;
    _isVideoMuted = !video;

    notifyListeners();
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
    notifyListeners();
  }

  /// Enables or disables the local video track (camera mute/unmute).
  void toggleVideo(bool enabled) {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = enabled;
    }
    _isVideoMuted = !enabled;
    notifyListeners();
  }

  /// Explicitly mutes or unmutes a remote peer's media track by kind ('audio' or 'video').
  void setRemoteTrackEnabled(String? userId, String kind, bool enabled) {
    if (userId != null && _remoteStreams.containsKey(userId)) {
      final stream = _remoteStreams[userId]!;
      if (kind == 'audio') {
        for (final track in stream.getAudioTracks()) {
          track.enabled = enabled;
        }
      } else if (kind == 'video') {
        for (final track in stream.getVideoTracks()) {
          track.enabled = enabled;
        }
      }
    } else {
      // If userId is omitted or empty, apply to all remote streams
      for (final stream in _remoteStreams.values) {
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
  }

  /// Retrieves or creates and initializes an [RTCVideoRenderer] for a given [userId].
  Future<RTCVideoRenderer> getOrCreateRemoteRenderer(String userId) async {
    final resolvedId = _aliases[userId] ?? userId;
    if (_remoteRenderers.containsKey(resolvedId)) {
      return _remoteRenderers[resolvedId]!;
    }

    final renderer = RTCVideoRenderer();
    try {
      await renderer.initialize();
    } catch (e) {
      OmniCastLogger.warn(
        '[MediaStreamManager] Failed to initialize RTCVideoRenderer for $userId: $e',
      );
    }
    _remoteRenderers[resolvedId] = renderer;

    final stream = _remoteStreams[resolvedId] ?? _remoteStreams[userId];
    if (stream != null) {
      renderer.srcObject = stream;
    }

    return renderer;
  }

  /// Attaches a remote [MediaStream] to storage and notifies listening UI components.
  Future<RTCVideoRenderer?> attachRemoteStream(
    String userId,
    MediaStream stream,
  ) async {
    final existingStream = _remoteStreams[userId];
    MediaStream effectiveStream;

    if (stream.getVideoTracks().isNotEmpty) {
      effectiveStream = stream;
      if (existingStream != null) {
        for (final at in existingStream.getAudioTracks()) {
          if (!effectiveStream.getTracks().any((t) => t.id == at.id || t.kind == 'audio')) {
            try {
              await effectiveStream.addTrack(at);
            } catch (_) {}
          }
        }
      }
    } else if (existingStream != null && existingStream.getVideoTracks().isNotEmpty) {
      effectiveStream = existingStream;
      for (final at in stream.getAudioTracks()) {
        if (!effectiveStream.getTracks().any((t) => t.id == at.id || t.kind == 'audio')) {
          try {
            await effectiveStream.addTrack(at);
          } catch (_) {}
        }
      }
    } else {
      effectiveStream = stream;
      if (existingStream != null) {
        for (final track in existingStream.getTracks()) {
          if (!effectiveStream.getTracks().any((t) => t.id == track.id || t.kind == track.kind)) {
            try {
              await effectiveStream.addTrack(track);
            } catch (_) {}
          }
        }
      }
    }

    _remoteStreams[userId] = effectiveStream;
    final resolvedId = _aliases[userId];
    if (resolvedId != null && resolvedId != userId) {
      _remoteStreams[resolvedId] = effectiveStream;
    }

    // If a UI renderer was already allocated for this user/alias, update its srcObject
    final matchingKeys = [
      userId,
      ?resolvedId,
      ..._aliases.keys.where((k) => _aliases[k] == userId || (resolvedId != null && _aliases[k] == resolvedId)),
    ];
    for (final k in matchingKeys) {
      final r = _remoteRenderers[k];
      if (r != null) {
        r.srcObject = effectiveStream;
      }
    }

    notifyListeners();
    return _remoteRenderers[resolvedId ?? userId] ?? _remoteRenderers[userId];
  }

  /// Safely removes and disposes the [RTCVideoRenderer] and cached stream for a given [userId].
  Future<void> removeRemoteRenderer(String userId) async {
    final resolvedId = _aliases[userId] ?? userId;
    final stream = _remoteStreams.remove(resolvedId) ?? _remoteStreams.remove(userId);
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }

    final renderer = _remoteRenderers.remove(resolvedId) ?? _remoteRenderers.remove(userId);
    if (renderer != null) {
      renderer.srcObject = null;
      await renderer.dispose();
    }
    notifyListeners();
  }

  /// Returns the remote [MediaStream] for a given [userId], checking direct keys,
  /// aliases, reverse aliases, sub-strings, numeric IDs, and single-stream fallbacks.
  MediaStream? getRemoteStream(String? userId) {
    if (userId == null || userId == 'local') return null;

    final candidates = <MediaStream>[];
    void addCandidate(MediaStream? s) {
      if (s != null && !candidates.contains(s)) {
        candidates.add(s);
      }
    }

    // 1. Direct match
    if (_remoteStreams.containsKey(userId)) {
      addCandidate(_remoteStreams[userId]);
    }
    
    // 2. Alias match
    final resolvedId = resolveUserId(userId);
    if (_remoteStreams.containsKey(resolvedId)) {
      addCandidate(_remoteStreams[resolvedId]);
    }

    // 3. Reverse alias match
    for (final entry in _aliases.entries) {
      if ((entry.value == userId || entry.value == resolvedId) &&
          _remoteStreams.containsKey(entry.key)) {
        addCandidate(_remoteStreams[entry.key]);
      }
    }

    // 4. Exact numeric ID match (e.g., 'user_3319' matches '3319' or '3319_name')
    final numMatch = RegExp(r'\d+').firstMatch(userId)?.group(0);
    if (numMatch != null && numMatch.isNotEmpty) {
      for (final entry in _remoteStreams.entries) {
        final entryNum = RegExp(r'\d+').firstMatch(entry.key)?.group(0);
        if (entryNum == numMatch) {
          addCandidate(entry.value);
        }
      }
    }

    // 5. Substring match
    for (final entry in _remoteStreams.entries) {
      if (entry.key == userId ||
          entry.key == resolvedId ||
          entry.key.contains(userId) ||
          userId.contains(entry.key)) {
        addCandidate(entry.value);
      }
    }

    // 6. Return candidate with video track first, or any candidate
    for (final c in candidates) {
      if (c.getVideoTracks().isNotEmpty) return c;
    }
    if (candidates.isNotEmpty) return candidates.first;

    // 7. Fallback: Host query, room ID query, or single remote stream fallback
    final isHostQuery = userId == 'host' ||
        userId.toLowerCase().contains('host') ||
        (resolveUserId(userId) == 'host');
    if (isHostQuery || _remoteStreams.length == 1) {
      if (_remoteStreams.containsKey('host')) {
        return _remoteStreams['host'];
      }
      for (final s in _remoteStreams.values) {
        if (s.getVideoTracks().isNotEmpty) return s;
      }
      if (_remoteStreams.isNotEmpty) return _remoteStreams.values.first;
    }
    
    // If 'host' stream is available and the requested userId is not a co-host with distinct stream
    if (_remoteStreams.containsKey('host') && !userId.startsWith('cohost_') && !userId.startsWith('pk-')) {
      final isCoHostWithStream = _remoteStreams.keys.any(
        (k) => k != 'host' && (k.contains(userId) || userId.contains(k)),
      );
      if (!isCoHostWithStream) {
        return _remoteStreams['host'];
      }
    }
    return null;
  }

  /// Returns the [RTCVideoRenderer] associated with a given [userId].
  /// Returns [localRenderer] if [userId] is null or 'local'.
  RTCVideoRenderer? getRenderer(String? userId) {
    if (userId == null || userId == 'local') {
      return _localRenderer;
    }
    final resolvedId = resolveUserId(userId);
    if (_remoteRenderers.containsKey(resolvedId)) {
      return _remoteRenderers[resolvedId];
    }
    if (_remoteRenderers.containsKey(userId)) {
      return _remoteRenderers[userId];
    }
    for (final entry in _remoteRenderers.entries) {
      if (entry.key == userId ||
          entry.key == resolvedId ||
          entry.key.contains(userId) ||
          userId.contains(entry.key) ||
          _aliases[entry.key] == userId ||
          _aliases[entry.key] == resolvedId) {
        return entry.value;
      }
    }
    final numMatch = RegExp(r'\d+').firstMatch(userId)?.group(0);
    if (numMatch != null && numMatch.isNotEmpty) {
      for (final entry in _remoteRenderers.entries) {
        if (entry.key.contains(numMatch) ||
            (_aliases[entry.key]?.contains(numMatch) ?? false)) {
          return entry.value;
        }
      }
    }
    if (_remoteRenderers.isNotEmpty) {
      if (userId == 'host' || _remoteRenderers.length == 1) {
        return _remoteRenderers.values.first;
      }
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
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Permanently disposes all hardware media streams, local renderer, and all remote renderers.
  @override
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

    final remoteIds = List<String>.from(_remoteRenderers.keys);
    for (final id in remoteIds) {
      await removeRemoteRenderer(id);
    }
    _remoteStreams.clear();
    _remoteRenderers.clear();
    _aliases.clear();

    super.dispose();
  }
}
