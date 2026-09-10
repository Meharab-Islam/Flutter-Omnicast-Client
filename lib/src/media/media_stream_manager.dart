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
  MediaStream? _screenStream;
  RTCVideoRenderer? _screenRenderer;
  MediaStreamTrack? _musicTrack;
  MediaStream? _musicStream;

  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, RTCVideoRenderer> _remoteScreenRenderers = {};
  final Map<String, MediaStream> _remoteScreenStreams = {};
  final Map<String, String> _aliases = {};

  VideoParameters _currentParameters = VideoParameters.presetSmooth480p;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isScreenSharing = false;
  bool _isDisposed = false;

  // Getters
  MediaStream? get localStream => _localStream;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  MediaStream? get screenStream => _screenStream;
  RTCVideoRenderer? get screenRenderer => _screenRenderer;
  MediaStreamTrack? get musicTrack => _musicTrack;
  MediaStream? get musicStream => _musicStream;
  bool get isScreenSharing => _isScreenSharing;
  bool get hasMusicTrack => _musicTrack != null;

  VideoParameters get currentParameters => _currentParameters;
  Map<String, RTCVideoRenderer> get remoteRenderers =>
      Map.unmodifiable(_remoteRenderers);
  Map<String, MediaStream> get remoteStreams =>
      Map.unmodifiable(_remoteStreams);
  Map<String, RTCVideoRenderer> get remoteScreenRenderers =>
      Map.unmodifiable(_remoteScreenRenderers);
  Map<String, MediaStream> get remoteScreenStreams =>
      Map.unmodifiable(_remoteScreenStreams);

  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoMuted => _isVideoMuted;
  bool get hasLocalStream => _localStream != null;

  /// Registers an alias for a user ID (e.g. mapping 'host' to a specific user ID).
  void registerAlias(String alias, String targetId) {
    _aliases[alias] = targetId;
    final aliasUnder = alias.replaceAll(' ', '_');
    final targetUnder = targetId.replaceAll(' ', '_');
    _aliases[aliasUnder] = targetId;
    _aliases[alias] = targetUnder;
    _aliases[aliasUnder] = targetUnder;

    final stream = _remoteStreams[targetId] ??
        _remoteStreams[alias] ??
        _remoteStreams[targetUnder] ??
        _remoteStreams[aliasUnder];
    if (stream != null) {
      _remoteStreams[alias] = stream;
      _remoteStreams[targetId] = stream;
      _remoteStreams[aliasUnder] = stream;
      _remoteStreams[targetUnder] = stream;
    }
  }

  /// Resolves an alias or canonical user ID (e.g. mapping alias to target user ID).
  String resolveUserId(String userId) => _aliases[userId] ?? userId;

  /// Initializes the local video renderer safely without leaking EGL contexts.
  Future<RTCVideoRenderer?> initLocalRenderer() async {
    if (_localRenderer != null) {
      if (_localStream != null && _localRenderer!.srcObject != _localStream) {
        _localRenderer!.srcObject = _localStream;
      }
      return _localRenderer!;
    }

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

  /// Initializes the local screen share video renderer.
  Future<RTCVideoRenderer?> initScreenRenderer() async {
    if (_screenRenderer != null) return _screenRenderer!;

    final renderer = RTCVideoRenderer();
    try {
      await renderer.initialize();
      _screenRenderer = renderer;
      if (_screenStream != null) {
        renderer.srcObject = _screenStream;
      }
    } catch (e) {
      OmniCastLogger.warn(
        '[MediaStreamManager] initScreenRenderer failed to allocate EGL context: $e',
      );
      return null;
    }
    notifyListeners();
    return renderer;
  }

  /// Starts capturing device display screen and optional system audio.
  Future<MediaStream?> startScreenShare({bool captureAudio = false}) async {
    if (_isDisposed) {
      throw StateError('Cannot start screen share on disposed MediaStreamManager');
    }

    await stopScreenShare();

    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': captureAudio,
        'video': {
          'mandatory': {
            'minWidth': '1280',
            'minHeight': '720',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        }
      };

      final stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      _screenStream = stream;
      _isScreenSharing = true;

      // Listen for screen share termination from OS system tray/notification
      for (final track in stream.getVideoTracks()) {
        track.onEnded = () {
          stopScreenShare();
        };
      }

      if (_screenRenderer != null) {
        _screenRenderer!.srcObject = stream;
      }

      notifyListeners();
      return stream;
    } catch (e) {
      OmniCastLogger.error('[MediaStreamManager] getDisplayMedia failed: $e');
      _isScreenSharing = false;
      notifyListeners();
      return null;
    }
  }

  /// Stops the local screen share stream and clears its renderer.
  Future<void> stopScreenShare() async {
    if (_screenStream != null) {
      for (final track in _screenStream!.getTracks()) {
        try {
          await track.stop();
        } catch (_) {}
      }
      try {
        await _screenStream!.dispose();
      } catch (_) {}
      _screenStream = null;
    }

    if (_screenRenderer != null) {
      _screenRenderer!.srcObject = null;
    }

    _isScreenSharing = false;
    notifyListeners();
  }

  /// Publishes a secondary auxiliary music/in-app audio track.
  Future<void> publishMusicTrack(MediaStreamTrack track) async {
    _musicTrack = track;
    try {
      _musicStream = await createLocalMediaStream('music_stream_${track.id}');
      await _musicStream!.addTrack(track);
    } catch (_) {}
    notifyListeners();
  }

  /// Stops publishing the secondary music track.
  Future<void> stopMusicTrack() async {
    if (_musicTrack != null) {
      try {
        await _musicTrack!.stop();
      } catch (_) {}
      _musicTrack = null;
    }
    if (_musicStream != null) {
      try {
        await _musicStream!.dispose();
      } catch (_) {}
      _musicStream = null;
    }
    notifyListeners();
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

    // Check if we already have an active local stream with the requested video/audio tracks
    final hasActiveVideo = _localStream != null &&
        _localStream!.getVideoTracks().any((t) => t.enabled && !(t.muted ?? false));
    final hasActiveAudio = _localStream != null &&
        _localStream!.getAudioTracks().isNotEmpty;

    if (_localStream != null &&
        (!video || hasActiveVideo) &&
        (!audio || hasActiveAudio) &&
        parameters == null &&
        width == null &&
        height == null) {
      OmniCastLogger.log(
        '[MediaStreamManager] Existing localStream is active, reusing without restarting camera hardware',
      );
      if (_localRenderer != null && _localRenderer!.srcObject != _localStream) {
        _localRenderer!.srcObject = _localStream;
      }
      _isAudioMuted = !audio;
      _isVideoMuted = !video;
      notifyListeners();
      return _localStream!;
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
    if (_localRenderer != null && _localRenderer!.srcObject != stream) {
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
    if (userId != null && userId.isNotEmpty) {
      final stream = getRemoteStream(userId);
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
      // If a specific userId was targeted, do NOT touch other users' streams!
      return;
    }

    // Only if userId is explicitly omitted/empty, apply to all remote streams
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

  /// Retrieves or creates and initializes an [RTCVideoRenderer] for a given [userId].
  Future<RTCVideoRenderer> getOrCreateRemoteRenderer(String userId) async {
    final resolvedId = _aliases[userId] ?? userId;
    if (_remoteRenderers.containsKey(resolvedId)) {
      final r = _remoteRenderers[resolvedId]!;
      final stream = getRemoteStream(userId);
      if (stream != null && r.srcObject != stream) {
        r.srcObject = stream;
      }
      return r;
    }
    if (_remoteRenderers.containsKey(userId)) {
      final r = _remoteRenderers[userId]!;
      final stream = getRemoteStream(userId);
      if (stream != null && r.srcObject != stream) {
        r.srcObject = stream;
      }
      return r;
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
    _remoteRenderers[userId] = renderer;

    final stream = getRemoteStream(userId);
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
              at.enabled = true;
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
            at.enabled = true;
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
              track.enabled = true;
              await effectiveStream.addTrack(track);
            } catch (_) {}
          }
        }
      }
    }

    // Explicitly guarantee all tracks in effectiveStream are enabled
    for (final t in effectiveStream.getTracks()) {
      try {
        t.enabled = true;
      } catch (_) {}
    }

    _remoteStreams[userId] = effectiveStream;
    final resolvedId = _aliases[userId];
    if (resolvedId != null && resolvedId != userId) {
      _remoteStreams[resolvedId] = effectiveStream;
    }
    for (final entry in _aliases.entries) {
      if (entry.key == userId || entry.value == userId || (resolvedId != null && (entry.key == resolvedId || entry.value == resolvedId))) {
        _remoteStreams[entry.key] = effectiveStream;
        _remoteStreams[entry.value] = effectiveStream;
      }
    }

    final primaryKey = resolvedId ?? userId;
    var primaryRenderer = _remoteRenderers[primaryKey] ?? _remoteRenderers[userId];
    if (primaryRenderer == null) {
      final newRenderer = RTCVideoRenderer();
      try {
        await newRenderer.initialize();
        newRenderer.srcObject = effectiveStream;
        _remoteRenderers[primaryKey] = newRenderer;
        _remoteRenderers[userId] = newRenderer;
        primaryRenderer = newRenderer;
      } catch (e) {
        OmniCastLogger.warn(
          '[MediaStreamManager] Failed to auto-initialize renderer for $primaryKey: $e',
        );
      }
    } else {
      primaryRenderer.srcObject = effectiveStream;
    }

    // Link all matching keys / aliases to this renderer and stream
    final matchingKeys = [
      userId,
      if (resolvedId != null) resolvedId,
      ..._aliases.keys.where((k) => _aliases[k] == userId || (resolvedId != null && _aliases[k] == resolvedId)),
    ];
    for (final k in matchingKeys) {
      var r = _remoteRenderers[k];
      if (r == null && primaryRenderer != null) {
        _remoteRenderers[k] = primaryRenderer;
      } else if (r != null) {
        r.srcObject = effectiveStream;
      }
    }

    notifyListeners();
    return primaryRenderer ?? _remoteRenderers[resolvedId ?? userId] ?? _remoteRenderers[userId];
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
      _remoteRenderers.removeWhere((k, v) => v == renderer);
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

    // 1. Direct match & space/underscore variants
    if (_remoteStreams.containsKey(userId)) {
      addCandidate(_remoteStreams[userId]);
    }
    final underId = userId.replaceAll(' ', '_');
    final spaceId = userId.replaceAll('_', ' ');
    if (_remoteStreams.containsKey(underId)) {
      addCandidate(_remoteStreams[underId]);
    }
    if (_remoteStreams.containsKey(spaceId)) {
      addCandidate(_remoteStreams[spaceId]);
    }
    
    // 2. Alias match
    final resolvedId = resolveUserId(userId);
    if (_remoteStreams.containsKey(resolvedId)) {
      addCandidate(_remoteStreams[resolvedId]);
    }
    final resolvedUnder = resolveUserId(underId);
    if (_remoteStreams.containsKey(resolvedUnder)) {
      addCandidate(_remoteStreams[resolvedUnder]);
    }

    // 3. Reverse alias match
    for (final entry in _aliases.entries) {
      if ((entry.value == userId || entry.value == resolvedId || entry.value == underId || entry.value == spaceId) &&
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

    // 5. Substring match (Never match 'host' or 'local' against arbitrary user IDs)
    for (final entry in _remoteStreams.entries) {
      if (entry.key == 'host' || entry.key == 'local') continue;
      if (entry.key == userId ||
          entry.key == resolvedId ||
          (entry.key.length >= 3 && userId.length >= 3 && (entry.key.contains(userId) || userId.contains(entry.key)))) {
        addCandidate(entry.value);
      }
    }

    // Check if this query is explicitly for the broadcaster/host
    final bool isHostQuery = userId == 'host' ||
        userId.toLowerCase().contains('host') ||
        resolveUserId(userId) == 'host' ||
        _aliases['host'] == userId;

    // Include 'host' stream as candidate ONLY if this query is actually targeting the host
    if (isHostQuery && _remoteStreams.containsKey('host')) {
      addCandidate(_remoteStreams['host']);
    }

    // 6. Return candidate with video track first
    for (final c in candidates) {
      if (c.getVideoTracks().isNotEmpty) return c;
    }

    // 7. Dynamic Host Fallback: check host stream for video tracks ONLY if asking for host
    if (isHostQuery && _remoteStreams.containsKey('host')) {
      final hostStream = _remoteStreams['host'];
      if (hostStream != null && hostStream.getVideoTracks().isNotEmpty) {
        return hostStream;
      }
    }

    if (candidates.isNotEmpty) return candidates.first;

    if (isHostQuery && _remoteStreams.containsKey('host')) {
      return _remoteStreams['host'];
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
    // Dynamic Host Fallback
    if (_remoteRenderers.containsKey('host')) {
      if (_remoteRenderers.length == 1 ||
          userId == 'host' ||
          userId.toLowerCase().contains('host') ||
          resolveUserId(userId) == 'host' ||
          !userId.startsWith('cohost_')) {
        return _remoteRenderers['host'];
      }
    }
    // Single remote renderer fallback
    if (_remoteRenderers.length == 1 && !userId.startsWith('cohost_')) {
      return _remoteRenderers.values.first;
    }
    if (_remoteRenderers.isNotEmpty && (userId == 'host' || !userId.startsWith('cohost_'))) {
      return _remoteRenderers.values.first;
    }
    return null;
  }

  /// Attaches a remote screen share [MediaStream] to storage and notifies listening UI components.
  Future<RTCVideoRenderer?> attachRemoteScreenStream(
    String userId,
    MediaStream stream,
  ) async {
    _remoteScreenStreams[userId] = stream;
    final resolvedId = _aliases[userId];
    if (resolvedId != null && resolvedId != userId) {
      _remoteScreenStreams[resolvedId] = stream;
    }

    final renderer = await getOrCreateRemoteScreenRenderer(userId);
    renderer.srcObject = stream;

    notifyListeners();
    return renderer;
  }

  /// Removes and disposes the remote screen share stream and renderer for a given [userId].
  Future<void> removeRemoteScreenStream(String userId) async {
    final resolvedId = _aliases[userId] ?? userId;
    final stream = _remoteScreenStreams.remove(resolvedId) ?? _remoteScreenStreams.remove(userId);
    if (stream != null) {
      for (final track in stream.getTracks()) {
        try {
          await track.stop();
        } catch (_) {}
      }
      try {
        await stream.dispose();
      } catch (_) {}
    }

    final renderer = _remoteScreenRenderers.remove(resolvedId) ?? _remoteScreenRenderers.remove(userId);
    if (renderer != null) {
      renderer.srcObject = null;
      try {
        await renderer.dispose();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Retrieves or creates and initializes an [RTCVideoRenderer] for screen sharing of a given [userId].
  Future<RTCVideoRenderer> getOrCreateRemoteScreenRenderer(String userId) async {
    final resolvedId = _aliases[userId] ?? userId;
    if (_remoteScreenRenderers.containsKey(resolvedId)) {
      return _remoteScreenRenderers[resolvedId]!;
    }

    final renderer = RTCVideoRenderer();
    try {
      await renderer.initialize();
    } catch (e) {
      OmniCastLogger.warn(
        '[MediaStreamManager] Failed to initialize RTCVideoRenderer for screen $userId: $e',
      );
    }
    _remoteScreenRenderers[resolvedId] = renderer;

    final stream = _remoteScreenStreams[resolvedId] ?? _remoteScreenStreams[userId];
    if (stream != null) {
      renderer.srcObject = stream;
    }

    return renderer;
  }

  /// Returns the remote screen share [MediaStream] for a given [userId].
  MediaStream? getRemoteScreenStream(String? userId) {
    if (userId == null || userId == 'local') return _screenStream;

    if (_remoteScreenStreams.containsKey(userId)) {
      return _remoteScreenStreams[userId];
    }
    final resolvedId = resolveUserId(userId);
    if (_remoteScreenStreams.containsKey(resolvedId)) {
      return _remoteScreenStreams[resolvedId];
    }

    for (final entry in _remoteScreenStreams.entries) {
      if (entry.key == userId || entry.key == resolvedId || entry.key.contains(userId) || userId.contains(entry.key)) {
        return entry.value;
      }
    }

    if (_remoteScreenStreams.isNotEmpty) {
      return _remoteScreenStreams.values.first;
    }
    return null;
  }

  /// Returns the remote screen share [RTCVideoRenderer] for a given [userId].
  RTCVideoRenderer? getRemoteScreenRenderer(String? userId) {
    if (userId == null || userId == 'local') return _screenRenderer;

    final resolvedId = resolveUserId(userId);
    if (_remoteScreenRenderers.containsKey(resolvedId)) {
      return _remoteScreenRenderers[resolvedId];
    }
    if (_remoteScreenRenderers.containsKey(userId)) {
      return _remoteScreenRenderers[userId];
    }

    for (final entry in _remoteScreenRenderers.entries) {
      if (entry.key == userId || entry.key == resolvedId || entry.key.contains(userId) || userId.contains(entry.key)) {
        return entry.value;
      }
    }

    if (_remoteScreenRenderers.isNotEmpty) {
      return _remoteScreenRenderers.values.first;
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
    await stopScreenShare();
    await stopMusicTrack();

    if (_localRenderer != null) {
      try {
        await _localRenderer!.dispose().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      } catch (_) {}
      _localRenderer = null;
    }

    if (_screenRenderer != null) {
      try {
        await _screenRenderer!.dispose().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      } catch (_) {}
      _screenRenderer = null;
    }

    final remoteIds = List<String>.from(_remoteRenderers.keys);
    for (final id in remoteIds) {
      await removeRemoteRenderer(id);
    }
    final remoteScreenIds = List<String>.from(_remoteScreenRenderers.keys);
    for (final id in remoteScreenIds) {
      await removeRemoteScreenStream(id);
    }
    _remoteStreams.clear();
    _remoteRenderers.clear();
    _remoteScreenStreams.clear();
    _remoteScreenRenderers.clear();
    _aliases.clear();

    super.dispose();
  }
}
