import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/room_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';
import 'global_media_config.dart';
import 'media_stream_manager.dart';
import 'video_parameters.dart';

/// Controls local hardware media, video quality presets, simulcast layers,
/// adaptive streaming, Dynacast throttling, audio-only room enforcement, and lifecycle management.
class MediaController with WidgetsBindingObserver {
  final MediaStreamManager _mediaStreamManager;
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;
  final GlobalMediaConfig _globalConfig;

  bool _adaptiveStreamingEnabled = true;
  bool _dynacastEnabled = true;
  final bool _autoPauseOnBackground;
  bool _wasCameraEnabledBeforePause = false;

  // Granular ValueNotifiers for headless UI reactivity
  final ValueNotifier<bool> isMicrophoneMutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCameraEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> simulcastLayerNotifier = ValueNotifier<String>('f');

  StreamSubscription? _dynacastSubscription;

  MediaController({
    required MediaStreamManager mediaStreamManager,
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
    GlobalMediaConfig? globalConfig,
    bool autoPauseOnBackground = true,
  })  : _mediaStreamManager = mediaStreamManager,
        _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState,
        _globalConfig = globalConfig ?? const GlobalMediaConfig(),
        _autoPauseOnBackground = globalConfig?.autoPauseOnBackground ?? autoPauseOnBackground {
    _adaptiveStreamingEnabled = _globalConfig.enableAdaptiveStreaming;
    _dynacastEnabled = _globalConfig.enableDynacast;

    _bindDynacastSignaling();
    if (_autoPauseOnBackground) {
      try {
        WidgetsBinding.instance.addObserver(this);
      } catch (_) {
        // Fallback when WidgetsBinding is not yet initialized (e.g. CLI/pure tests)
      }
    }
  }

  MediaStreamManager get streamManager => _mediaStreamManager;
  WebRTCManager get webRTCManager => _webRTCManager;
  GlobalMediaConfig get globalConfig => _globalConfig;
  VideoParameters get currentParameters => _mediaStreamManager.currentParameters;
  bool get isMicrophoneMuted => isMicrophoneMutedNotifier.value;
  bool get isCameraEnabled => isCameraEnabledNotifier.value;
  bool get adaptiveStreamingEnabled => _adaptiveStreamingEnabled;
  bool get dynacastEnabled => _dynacastEnabled;
  String get currentSimulcastLayer => simulcastLayerNotifier.value;

  /// App Lifecycle Optimization: Automatically pause camera on background to save battery & CPU.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_autoPauseOnBackground || _roomState.isAudioOnly) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (isCameraEnabled) {
        _wasCameraEnabledBeforePause = true;
        debugPrint('[MediaController Lifecycle] App paused -> Pausing local camera');
        setCameraEnabled(false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasCameraEnabledBeforePause) {
        _wasCameraEnabledBeforePause = false;
        debugPrint('[MediaController Lifecycle] App resumed -> Resuming local camera');
        setCameraEnabled(true);
      }
    }
  }

  /// Binds to SFU Dynacast layer consumption signals.
  void _bindDynacastSignaling() {
    _dynacastSubscription = _signalingClient.onMessage.listen((msg) {
      if (!_dynacastEnabled || _roomState.isAudioOnly) return;

      if (msg.event == 'dynacast_layer_update' || msg.event == 'publisher_layers_update') {
        if (msg.payload is Map<String, dynamic>) {
          final payload = msg.payload as Map<String, dynamic>;
          final subscribedLayers = payload['subscribed_layers'] as List<dynamic>? ?? [];

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
    if (_roomState.isAudioOnly) return;

    if (_mediaStreamManager.hasLocalStream) {
      await _mediaStreamManager.openUserMedia(parameters: parameters);
      if (_webRTCManager.hasPeerConnection) {
        await _webRTCManager.addLocalMediaTracks(
          enableSimulcast: _webRTCManager.simulcastEnabled,
        );
      }
    }
  }

  /// Starts local hardware media capture and publishes streams as Host with custom metadata and JWT token.
  /// Strictly enforces audio-only (zero video bandwidth & zero camera permission) if roomType == RoomType.audio.
  Future<void> startAsHost({
    required String roomId,
    required String userId,
    required String token,
    RoomType roomType = RoomType.video,
    Map<String, dynamic>? metadata,
    VideoParameters? videoParameters,
    bool? enableSimulcast,
  }) async {
    if (!_signalingClient.isConnected && _signalingClient.wsUrl != null) {
      await _signalingClient.connect(wsUrl: _signalingClient.wsUrl!, token: token);
    }

    _roomState.updateRoomType(roomType);
    final isAudioOnly = roomType == RoomType.audio || _roomState.isAudioOnly;

    final params = videoParameters ?? _globalConfig.defaultResolution;
    final simulcast = isAudioOnly ? false : (enableSimulcast ?? _globalConfig.enableSimulcast);

    // Automated Track Disabling: Enforce video: false in getUserMedia constraints for audio-only
    await _mediaStreamManager.openUserMedia(
      audio: true,
      video: !isAudioOnly,
      parameters: params,
    );

    isCameraEnabledNotifier.value = !isAudioOnly;

    await _webRTCManager.addLocalMediaTracks(
      enableSimulcast: simulcast,
    );

    final offer = await _webRTCManager.createAndSetLocalOffer();

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.publish,
      roomId: roomId,
      userId: userId,
      payload: {
        'token': token,
        'sdp': offer.sdp,
        'type': offer.type,
        'room_type': roomType.name,
        'simulcast': simulcast,
        'metadata': ?metadata,
      },
    ));
  }

  /// Enables or mutes the local microphone.
  void setMicrophoneMuted(bool muted) {
    _mediaStreamManager.toggleAudio(!muted);
    isMicrophoneMutedNotifier.value = muted;
  }

  /// Enables or disables the local camera feed (no-op if audio-only).
  void setCameraEnabled(bool enabled) {
    if (_roomState.isAudioOnly) {
      isCameraEnabledNotifier.value = false;
      return;
    }
    _mediaStreamManager.toggleVideo(enabled);
    isCameraEnabledNotifier.value = enabled;
  }

  /// Switches between front and back camera.
  Future<void> switchCamera() async {
    if (_roomState.isAudioOnly) return;
    await _mediaStreamManager.switchCamera();
  }

  /// Sets the preferred simulcast layer subscription: `'f'` (high), `'h'` (medium), `'q'` (low).
  void setSimulcastLayer(String layer, {String? targetUserId}) {
    if (_roomState.isAudioOnly) return;
    if (layer != 'f' && layer != 'h' && layer != 'q') {
      debugPrint('[MediaController] Invalid simulcast layer: $layer (expected f, h, or q)');
      return;
    }
    simulcastLayerNotifier.value = layer;
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
    if (!enable && !_roomState.isAudioOnly) {
      _webRTCManager.setPublisherLayerActive('f', true);
      _webRTCManager.setPublisherLayerActive('h', true);
      _webRTCManager.setPublisherLayerActive('q', true);
    }
  }

  /// Requests a specific simulcast layer from the SFU for a given remote peer.
  void requestLayerForUser({required String targetUserId, required String layer}) {
    if (_roomState.isAudioOnly) return;
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
    if (!_dynacastEnabled || _roomState.isAudioOnly) return;
    _signalingClient.send(SignalingMessage(
      event: isVisible ? SignalingEvents.trackResume : SignalingEvents.trackPause,
      roomId: '',
      userId: '',
      targetUser: targetUserId,
    ));
  }

  /// Disposes internal listeners, observers, and atomic notifiers.
  void dispose() {
    if (_autoPauseOnBackground) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
    }
    _dynacastSubscription?.cancel();
    isMicrophoneMutedNotifier.dispose();
    isCameraEnabledNotifier.dispose();
    simulcastLayerNotifier.dispose();
  }
}
