import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OmniCastConfig & Token Configuration', () {
    test('creates valid token-based config without exposed secrets', () {
      const config = OmniCastConfig(
        hostUrl: 'wss://omnilive.lolipoplive.top/ws',
        heartbeatInterval: Duration(seconds: 15),
      );

      expect(config.hostUrl, 'wss://omnilive.lolipoplive.top/ws');
      expect(config.heartbeatInterval, const Duration(seconds: 15));
      expect(config.iceServers, isNotEmpty);
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
