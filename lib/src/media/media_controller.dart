import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../webrtc/webrtc_manager.dart';
import 'media_stream_manager.dart';
import 'video_parameters.dart';

/// Controls local hardware media, video quality presets, simulcast layers,
/// adaptive streaming subscriptions, and Dynacast upstream publisher throttling.
class MediaController {
  final MediaStreamManager _mediaStreamManager;
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;

  bool _adaptiveStreamingEnabled = true;
  bool _dynacastEnabled = true;
  String _currentSimulcastLayer = 'f'; // 'f' (high), 'h' (medium), 'q' (low)
  StreamSubscription? _dynacastSubscription;

  MediaController({
    required MediaStreamManager mediaStreamManager,
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
  })  : _mediaStreamManager = mediaStreamManager,
        _signalingClient = signalingClient,
        _webRTCManager = webRTCManager {
    _bindDynacastSignaling();
  }

  MediaStreamManager get streamManager => _mediaStreamManager;
  WebRTCManager get webRTCManager => _webRTCManager;
  VideoParameters get currentParameters => _mediaStreamManager.currentParameters;
  bool get isMicrophoneMuted => _mediaStreamManager.isAudioMuted;
  bool get isCameraEnabled => !_mediaStreamManager.isVideoMuted;
  bool get adaptiveStreamingEnabled => _adaptiveStreamingEnabled;
  bool get dynacastEnabled => _dynacastEnabled;
  String get currentSimulcastLayer => _currentSimulcastLayer;

  /// Binds to SFU Dynacast layer consumption signals.
  void _bindDynacastSignaling() {
    _dynacastSubscription = _signalingClient.onMessage.listen((msg) {
      if (!_dynacastEnabled) return;

      // Event triggered when SFU updates which publisher layers are currently consumed
      if (msg.event == 'dynacast_layer_update' || msg.event == 'publisher_layers_update') {
        if (msg.payload is Map<String, dynamic>) {
          final payload = msg.payload as Map<String, dynamic>;
          final subscribedLayers = payload['subscribed_layers'] as List<dynamic>? ?? [];

          // If no viewers subscribe to 'f' layer, pause 'f' upstream to save upload bandwidth
          final hasFullSubscribers = subscribedLayers.contains('f');
          final hasHalfSubscribers = subscribedLayers.contains('h');
          final hasQuarterSubscribers = subscribedLayers.contains('q');

          _webRTCManager.setPublisherLayerActive('f', hasFullSubscribers);
          _webRTCManager.setPublisherLayerActive('h', hasHalfSubscribers);
          _webRTCManager.setPublisherLayerActive('q', hasQuarterSubscribers || !hasFullSubscribers && !hasHalfSubscribers);
        }
      }
    });
  }

  /// Sets custom video capture resolution and framerate parameters.
  Future<void> setVideoParameters(VideoParameters parameters) async {
    if (_mediaStreamManager.hasLocalStream) {
      await _mediaStreamManager.openUserMedia(parameters: parameters);
      if (_webRTCManager.hasPeerConnection) {
        await _webRTCManager.addLocalMediaTracks(
          enableSimulcast: _webRTCManager.simulcastEnabled,
        );
      }
    }
  }

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

  /// Sets the preferred simulcast layer subscription: `'f'` (high), `'h'` (medium), `'q'` (low).
  void setSimulcastLayer(String layer, {String? targetUserId}) {
    if (layer != 'f' && layer != 'h' && layer != 'q') {
      debugPrint('[MediaController] Invalid simulcast layer: $layer (expected f, h, or q)');
      return;
    }
    _currentSimulcastLayer = layer;
    _signalingClient.send(SignalingMessage(
      event: 'request_layer',
      roomId: '',
      userId: '',
      targetUser: targetUserId,
      payload: {'layer': layer},
    ));
  }

  /// Enables or disables adaptive streaming bandwidth management for viewers.
  void enableAdaptiveStreaming(bool enable) {
    _adaptiveStreamingEnabled = enable;
  }

  /// Enables or disables Dynacast smart publisher layer muting.
  void enableDynacast(bool enable) {
    _dynacastEnabled = enable;
    if (!enable) {
      // If Dynacast is disabled, reactivate all layers
      _webRTCManager.setPublisherLayerActive('f', true);
      _webRTCManager.setPublisherLayerActive('h', true);
      _webRTCManager.setPublisherLayerActive('q', true);
    }
  }

  /// Requests a specific simulcast layer from the SFU for a given remote peer.
  void requestLayerForUser({required String targetUserId, required String layer}) {
    if (layer != 'f' && layer != 'h' && layer != 'q') return;

    _signalingClient.send(SignalingMessage(
      event: 'request_layer',
      roomId: '',
      userId: '',
      targetUser: targetUserId,
      payload: {'layer': layer},
    ));
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

  /// Disposes internal listeners.
  void dispose() {
    _dynacastSubscription?.cancel();
  }
}
