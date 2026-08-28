import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import 'media_stream_manager.dart';

/// Controls local hardware media, simulcast layers, adaptive streaming, and dynacast.
class MediaController {
  final MediaStreamManager _mediaStreamManager;
  final SignalingClient _signalingClient;

  bool _adaptiveStreamingEnabled = true;
  bool _dynacastEnabled = true;
  String _currentSimulcastLayer = 'f'; // 'f' (full/high), 'h' (half/medium), 'q' (quarter/low)

  MediaController({
    required MediaStreamManager mediaStreamManager,
    required SignalingClient signalingClient,
  })  : _mediaStreamManager = mediaStreamManager,
        _signalingClient = signalingClient;

  MediaStreamManager get streamManager => _mediaStreamManager;
  bool get isMicrophoneMuted => _mediaStreamManager.isAudioMuted;
  bool get isCameraEnabled => !_mediaStreamManager.isVideoMuted;
  bool get adaptiveStreamingEnabled => _adaptiveStreamingEnabled;
  bool get dynacastEnabled => _dynacastEnabled;
  String get currentSimulcastLayer => _currentSimulcastLayer;

  /// Enables or mutes the local microphone.
  void setMicrophoneMuted(bool muted) {
    _mediaStreamManager.toggleAudio(!muted);
  }

  /// Enables or disables the local camera feed.
  void setCameraEnabled(bool enabled) {
    _mediaStreamManager.toggleVideo(enabled);
  }

  /// Switches between front and back camera.
  Future<void> switchCamera() => _mediaStreamManager.switchCamera();

  /// Sets the preferred simulcast layer: `'f'` (high), `'h'` (medium), `'q'` (low).
  void setSimulcastLayer(String layer) {
    if (layer != 'f' && layer != 'h' && layer != 'q') {
      debugPrint('[MediaController] Invalid simulcast layer: $layer (expected f, h, or q)');
      return;
    }
    _currentSimulcastLayer = layer;
    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.layerSelect,
      roomId: '',
      userId: '',
      payload: {'layer': layer},
    ));
  }

  /// Enables or disables adaptive streaming bandwidth management.
  void enableAdaptiveStreaming(bool enable) {
    _adaptiveStreamingEnabled = enable;
  }

  /// Enables or disables Dynacast (pausing/resuming remote video tracks based on visibility).
  void enableDynacast(bool enable) {
    _dynacastEnabled = enable;
  }

  /// Requests the SFU to dynamically pause/resume a remote peer's video track.
  void setRemoteTrackVisibility(String targetUserId, bool isVisible) {
    if (!_dynacastEnabled) return;
    _signalingClient.send(SignalingMessage(
      event: isVisible ? SignalingEvents.trackResume : SignalingEvents.trackPause,
      roomId: '',
      userId: '',
      targetUser: targetUserId,
    ));
  }
}
