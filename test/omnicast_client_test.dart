import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OmniCastConfig & Credentials', () {
    test('generates valid signed auth token', () {
      const config = OmniCastConfig(
        apiKey: 'test_api_key',
        apiSecret: 'test_secret_123',
        hostUrl: 'wss://sfu.omnicast.live/ws',
      );

      final token = config.generateAuthToken(
        userId: 'user_42',
        roomId: 'room_101',
      );

      expect(token, isNotEmpty);
    });
  });

  group('Sub-module Instantiation & Facade Structure', () {
    test('initializes sub-managers with reactive state', () {
      final roomState = RoomState();
      final signalingClient = SignalingClient();
      final mediaStreamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: mediaStreamManager);

      final roomManager = RoomManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

      final mediaController = MediaController(
        mediaStreamManager: mediaStreamManager,
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
      );

      final seatManager = SeatManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

      final interactionManager = InteractionManager(
        signalingClient: signalingClient,
        roomState: roomState,
      );

      final pkManager = PKManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

      expect(roomManager, isNotNull);
      expect(mediaController, isNotNull);
      expect(seatManager, isNotNull);
      expect(interactionManager, isNotNull);
      expect(pkManager, isNotNull);

      // Verify media controller default states
      expect(mediaController.currentSimulcastLayer, 'f');
      expect(mediaController.adaptiveStreamingEnabled, isTrue);
      expect(mediaController.dynacastEnabled, isTrue);
    });
  });
}
