import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OmniCastTokenGenerator', () {
    test('generates valid JWT token string with claims and metadata', () {
      final token = OmniCastTokenGenerator.generate(
        apiKey: 'api_key_test',
        apiSecret: 'super_secret_key_1234567890123456',
        roomId: 'room_101',
        userId: 'user_42',
        role: 'host',
        metadata: {'vip': true, 'level': 99},
      );

      expect(token, isNotEmpty);
      expect(token.split('.').length, 3); // Standard JWT Header.Payload.Signature
    });
  });

  group('SeatManager Co-Host Flow & Seamless Upgrades', () {
    late RoomState roomState;
    late SignalingClient signalingClient;
    late MediaStreamManager mediaStreamManager;
    late WebRTCManager webRTCManager;
    late SeatManager seatManager;

    setUp(() {
      roomState = RoomState();
      signalingClient = SignalingClient();
      mediaStreamManager = MediaStreamManager();
      webRTCManager = WebRTCManager(mediaStreamManager: mediaStreamManager);

      seatManager = SeatManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );
    });

    tearDown(() async {
      await seatManager.dispose();
      await webRTCManager.dispose();
      await mediaStreamManager.dispose();
      await signalingClient.dispose();
      roomState.dispose();
    });

    test('Viewer requesting seat updates pending list and notifies listeners', () {
      roomState.setSession(
        roomId: 'room_1',
        userId: 'host_1',
        role: UserRole.host,
      );

      roomState.addSeatRequest(SeatRequest(
        requesterId: 'viewer_99',
        requesterName: 'Viewer 99',
        preferredSeatIndex: 2,
        requestedAt: DateTime.now(),
      ));

      expect(roomState.pendingSeatRequests.length, 1);
      expect(seatManager.pendingSeatRequestsNotifier.value.length, 1);
      expect(seatManager.pendingSeatRequestsNotifier.value.first.requesterId, 'viewer_99');

      // Host accepts seat request
      seatManager.acceptSeatRequest('viewer_99', seatIndex: 2);
      expect(roomState.pendingSeatRequests, isEmpty);
      expect(seatManager.pendingSeatRequestsNotifier.value, isEmpty);
    });

    test('Host inviting viewer updates pending invites list and notifies listeners', () {
      roomState.setSession(
        roomId: 'room_1',
        userId: 'viewer_88',
        role: UserRole.viewer,
      );

      roomState.addInvite(CoHostInvite(
        inviteId: 'inv_101',
        hostId: 'host_1',
        targetUserId: 'viewer_88',
        seatIndex: 1,
        createdAt: DateTime.now(),
      ));

      expect(roomState.pendingInvites.length, 1);
      expect(seatManager.pendingInvitesNotifier.value.length, 1);
      expect(seatManager.pendingInvitesNotifier.value.first.inviteId, 'inv_101');

      // Viewer rejects invite
      seatManager.rejectCoHostInvite(inviteId: 'inv_101');
      expect(roomState.pendingInvites, isEmpty);
      expect(seatManager.pendingInvitesNotifier.value, isEmpty);
    });
  });
}
