import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlobalMediaConfig & Initialization', () {
    test('default GlobalMediaConfig has standard HD720p and enabled features', () {
      const config = GlobalMediaConfig();
      expect(config.defaultResolution, VideoParameters.presetHD720p);
      expect(config.enableSimulcast, isTrue);
      expect(config.enableDynacast, isTrue);
      expect(config.enableAdaptiveStreaming, isTrue);
      expect(config.autoPauseOnBackground, isTrue);
    });

    test('custom GlobalMediaConfig overrides defaults in OmniCastClient', () async {
      final client = await OmniCastClient.init(
        hostUrl: 'wss://omnilive.lolipoplive.top/ws',
        mediaConfig: const GlobalMediaConfig(
          defaultResolution: VideoParameters.presetFHD1080p,
          enableSimulcast: false,
          enableDynacast: false,
          enableAdaptiveStreaming: false,
        ),
      );

      expect(client.mediaConfig.defaultResolution, VideoParameters.presetFHD1080p);
      expect(client.media.dynacastEnabled, isFalse);
      expect(client.media.adaptiveStreamingEnabled, isFalse);

      await client.dispose();
    });
  });

  group('Audio-Only Room Logic (Zero Video Bandwidth)', () {
    late RoomState roomState;
    late SignalingClient signalingClient;
    late MediaStreamManager mediaStreamManager;
    late WebRTCManager webRTCManager;
    late MediaController mediaController;

    setUp(() {
      roomState = RoomState();
      signalingClient = SignalingClient();
      mediaStreamManager = MediaStreamManager();
      webRTCManager = WebRTCManager(mediaStreamManager: mediaStreamManager);

      mediaController = MediaController(
        mediaStreamManager: mediaStreamManager,
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );
    });

    tearDown(() async {
      mediaController.dispose();
      await webRTCManager.dispose();
      await mediaStreamManager.dispose();
      await signalingClient.dispose();
      roomState.dispose();
    });

    test('RoomOptions audio-only serialization sets video and simulcast to false', () {
      const audioOptions = RoomOptions(
        title: 'Clubhouse Audio Space 🎙️',
        roomType: RoomType.audio,
        enableAudio: true,
        enableVideo: true, // Should be overridden by isAudioOnly
        enableSimulcast: true,
      );

      expect(audioOptions.isAudioOnly, isTrue);
      final json = audioOptions.toJson();
      expect(json['room_type'], 'audio');
      expect(json['enable_video'], isFalse);
      expect(json['enable_simulcast'], isFalse);
    });

    test('MediaController enforces camera disabled in audio-only rooms', () {
      roomState.setSession(
        roomId: 'audio_room_1',
        userId: 'host_1',
        role: UserRole.host,
        roomType: RoomType.audio,
      );

      expect(roomState.isAudioOnly, isTrue);

      // Attempting to enable camera in audio-only room is blocked
      mediaController.setCameraEnabled(true);
      expect(mediaController.isCameraEnabled, isFalse);
    });
  });
}
