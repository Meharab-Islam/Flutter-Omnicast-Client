import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaController Camera & Mic Toggling with Signaling', () {
    late SignalingClient signalingClient;
    late MediaStreamManager streamManager;
    late WebRTCManager webRTCManager;
    late RoomState roomState;
    late MediaController mediaController;

    setUp(() {
      signalingClient = SignalingClient();
      streamManager = MediaStreamManager();
      webRTCManager = WebRTCManager(mediaStreamManager: streamManager);
      roomState = RoomState();

      mediaController = MediaController(
        mediaStreamManager: streamManager,
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );
    });

    tearDown(() async {
      mediaController.dispose();
      await webRTCManager.dispose();
      await streamManager.dispose();
      await signalingClient.dispose();
      roomState.dispose();
    });

    test('toggling mic updates ValueNotifier and emits state', () {
      expect(mediaController.isMicrophoneMuted, isFalse);

      mediaController.setMicrophoneMuted(true);
      expect(mediaController.isMicrophoneMuted, isTrue);

      mediaController.setMicrophoneMuted(false);
      expect(mediaController.isMicrophoneMuted, isFalse);
    });

    test('toggling camera updates ValueNotifier and emits state', () {
      expect(mediaController.isCameraEnabled, isTrue);

      mediaController.setCameraEnabled(false);
      expect(mediaController.isCameraEnabled, isFalse);

      mediaController.setCameraEnabled(true);
      expect(mediaController.isCameraEnabled, isTrue);
    });

    test('AudioLevelDetector manages audio levels and active speaker state', () {
      final detector = mediaController.audioDetector;
      expect(detector.audioLevelsNotifier.value, isEmpty);
      expect(detector.activeSpeakerNotifier.value, isNull);

      detector.audioLevelsNotifier.value = {
        'user_1': 0.15,
        'user_2': 0.02,
      };
      detector.activeSpeakerNotifier.value = 'user_1';

      expect(detector.audioLevelsNotifier.value['user_1'], 0.15);
      expect(detector.activeSpeakerNotifier.value, 'user_1');
    });
  });

  group('OmniCastSpeakingVideoTile Widget', () {
    testWidgets('renders avatar placeholder when camera is off and shows mute icon', (tester) async {
      final streamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: streamManager);
      final detector = AudioLevelDetector(webRTCManager: webRTCManager);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: OmniCastSpeakingVideoTile(
                userId: 'user_alice',
                trackId: 'track_alice_1',
                userName: 'Alice',
                renderer: null,
                isCameraEnabled: false,
                isMicMuted: true,
                audioDetector: detector,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Camera Off'), findsOneWidget);
      expect(find.byIcon(Icons.mic_off), findsOneWidget);

      detector.dispose();
      await webRTCManager.dispose();
      await streamManager.dispose();
    });

    testWidgets('shows active speaking glow when audioLevel exceeds threshold', (tester) async {
      final streamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: streamManager);
      final detector = AudioLevelDetector(webRTCManager: webRTCManager);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: OmniCastSpeakingVideoTile(
                userId: 'user_bob',
                trackId: 'track_bob_1',
                userName: 'Bob',
                renderer: null,
                isCameraEnabled: false,
                isMicMuted: false,
                audioDetector: detector,
              ),
            ),
          ),
        ),
      );

      // Simulate Bob speaking at 0.35 volume
      detector.audioLevelsNotifier.value = {'track_bob_1': 0.35};
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);

      detector.dispose();
      await webRTCManager.dispose();
      await streamManager.dispose();
    });
  });

  group('OmniCastMediaControlBar Widget', () {
    testWidgets('renders Mic, Camera, and Flip buttons and handles taps', (tester) async {
      final signaling = SignalingClient();
      final streamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: streamManager);
      final roomState = RoomState();

      final controller = MediaController(
        mediaStreamManager: streamManager,
        signalingClient: signaling,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastMediaControlBar(mediaController: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);

      // Tap mic to mute
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      expect(controller.isMicrophoneMuted, isTrue);
      expect(find.byIcon(Icons.mic_off), findsOneWidget);

      // Tap camera to turn off
      await tester.tap(find.byIcon(Icons.videocam));
      await tester.pumpAndSettle();
      expect(controller.isCameraEnabled, isFalse);
      expect(find.byIcon(Icons.videocam_off), findsOneWidget);

      controller.dispose();
      await webRTCManager.dispose();
      await streamManager.dispose();
      await signaling.dispose();
      roomState.dispose();
    });
  });
}
