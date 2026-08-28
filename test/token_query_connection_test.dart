import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocket URL Token Appending & Auto-Generation', () {
    test('SignalingClient stores and formats token into WebSocket URL query', () async {
      final client = SignalingClient();

      // We test URI parsing without network connection by checking stored state
      expect(client.isConnected, isFalse);

      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ1c2VyXzEifQ.xyz';
      
      try {
        await client.connect(
          wsUrl: 'ws://178.162.252.30:8080/ws',
          token: testToken,
        );
      } catch (_) {
        // Expected offline connection exception in local test
      }

      expect(client.wsUrl, 'ws://178.162.252.30:8080/ws');
      expect(client.token, testToken);

      await client.dispose();
    });

    test('RoomManager generates token and executes connection with token attached', () async {
      final signalingClient = SignalingClient();
      final roomState = RoomState();
      final mediaStreamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: mediaStreamManager);

      const config = OmniCastConfig(
        hostUrl: 'ws://178.162.252.30:8080/ws',
        apiKey: 'test_key',
        apiSecret: 'test_secret_1234567890123456',
        jwtSecret: 'jwt_secret_1234567890123456',
      );

      final roomManager = RoomManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
        config: config,
      );

      try {
        await roomManager.createRoom(
          roomId: 'room_101',
          userId: 'host_42',
        );
      } catch (_) {}

      expect(signalingClient.token, isNotEmpty);
      expect(signalingClient.token, contains('.')); // Valid JWT structure

      roomManager.dispose();
      await webRTCManager.dispose();
      await mediaStreamManager.dispose();
      await signalingClient.dispose();
      roomState.dispose();
    });
  });
}
