import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real-Time Participant & Viewer Tracking', () {
    late RoomState roomState;
    late SignalingClient signalingClient;
    late MediaStreamManager mediaStreamManager;
    late WebRTCManager webRTCManager;
    late RoomManager roomManager;

    setUp(() {
      roomState = RoomState();
      signalingClient = SignalingClient();
      mediaStreamManager = MediaStreamManager();
      webRTCManager = WebRTCManager(mediaStreamManager: mediaStreamManager);

      roomManager = RoomManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );
    });

    tearDown(() async {
      roomManager.dispose();
      await webRTCManager.dispose();
      await mediaStreamManager.dispose();
      await signalingClient.dispose();
      roomState.dispose();
    });

    test('OmniCastParticipant serialization and deserialization', () {
      final now = DateTime.now();
      final p = OmniCastParticipant(
        userId: 'viewer_42',
        displayName: 'StarViewer',
        avatarUrl: 'https://example.com/avatar.png',
        role: UserRole.viewer,
        isAudioMuted: false,
        isVideoMuted: false,
        joinedAt: now,
        metadata: {'badge': 'vip'},
      );

      final json = p.toJson();
      final fromJson = OmniCastParticipant.fromJson(json);

      expect(fromJson.userId, 'viewer_42');
      expect(fromJson.displayName, 'StarViewer');
      expect(fromJson.avatarUrl, 'https://example.com/avatar.png');
      expect(fromJson.role, UserRole.viewer);
      expect(fromJson.metadata?['badge'], 'vip');
    });

    test('RoomManager totalViewerCount and activeViewersList atomic updates', () async {
      expect(roomManager.totalViewerCount.value, 0);
      expect(roomManager.activeViewersList.value, isEmpty);

      // Simulate room_info_sync
      roomState.syncRoomInfo({
        'room_id': 'room_1',
        'viewers_count': 3,
        'viewers': [
          {'user_id': 'u1', 'display_name': 'Alice'},
          {'user_id': 'u2', 'display_name': 'Bob'},
          {'user_id': 'u3', 'display_name': 'Charlie'},
        ],
      });

      expect(roomManager.totalViewerCount.value, 3);
      expect(roomManager.activeViewersList.value.length, 3);
      expect(roomManager.activeViewersList.value.first.userId, 'u1');

      // Simulate real-time user_joined
      roomState.addParticipant(OmniCastParticipant(
        userId: 'u4',
        displayName: 'Diana',
        joinedAt: DateTime.now(),
      ));

      expect(roomManager.totalViewerCount.value, 4);
      expect(roomManager.activeViewersList.value.length, 4);
      expect(roomManager.activeViewersList.value.first.userId, 'u4');

      // Simulate real-time user_left
      roomState.removeParticipant('u2');

      expect(roomManager.totalViewerCount.value, 3);
      expect(roomManager.activeViewersList.value.any((p) => p.userId == 'u2'), isFalse);
    });

    testWidgets('Frontend developer horizontal avatar ListView.builder rendering',
        (tester) async {
      roomManager.totalViewerCount.value = 2;
      roomManager.activeViewersList.value = [
        OmniCastParticipant(
          userId: 'user_1',
          displayName: 'Alex',
          joinedAt: DateTime.now(),
        ),
        OmniCastParticipant(
          userId: 'user_2',
          displayName: 'Bella',
          joinedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // 1. Viewer count badge
                ValueListenableBuilder<int>(
                  valueListenable: roomManager.totalViewerCount,
                  builder: (context, count, _) {
                    return Text('👁️ $count');
                  },
                ),

                // 2. Horizontal Avatar List
                SizedBox(
                  height: 48,
                  child: ValueListenableBuilder<List<OmniCastParticipant>>(
                    valueListenable: roomManager.activeViewersList,
                    builder: (context, viewers, _) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: viewers.length,
                        itemBuilder: (context, index) {
                          final viewer = viewers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: CircleAvatar(
                              radius: 18,
                              child: Text(viewer.displayName?[0] ?? 'U'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('👁️ 2'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
