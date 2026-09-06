import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Late Joiner State Synchronization & Helper Facades', () {
    test('syncRoomInfo populates active seats, mic/cam mute states, and counts for late joiners', () {
      final roomState = RoomState();

      // Late-joiner payload received from server
      roomState.syncRoomInfo({
        'room_id': 'room-sync-101',
        'host_id': 'host-alice',
        'viewers_count': 42,
        'host_score': 1500,
        'media_states': {
          'host-alice': {'muted_audio': false, 'muted_video': false},
          'user-bob': {'muted_audio': true, 'muted_video': false},
          'user-carol': {'muted_audio': false, 'muted_video': true},
        },
        'active_seats': {
          '1': 'user-bob',
          '2': 'user-carol',
        },
        'waiting_list': [
          {
            'requester_id': 'user-dave',
            'requester_name': 'Dave',
            'preferred_seat_index': 3,
          }
        ],
      });

      expect(roomState.roomId, 'room-sync-101');
      expect(roomState.hostId, 'host-alice');
      expect(roomState.viewersCount, 42);
      expect(roomState.hostCoinBalance, 1500);

      // Verify seats
      expect(roomState.activeSeats.length, 2);
      expect(roomState.occupiedSeatsCount, 2);
      expect(roomState.occupiedSeats.length, 2);

      // Verify Bob on seat 1
      final bobSeat = roomState.getSeat(1);
      expect(bobSeat, isNotNull);
      expect(bobSeat!.userId, 'user-bob');
      expect(bobSeat.isMuted, true);
      expect(bobSeat.isCameraOff, false);
      expect(roomState.isUserMuted('user-bob'), true);
      expect(roomState.isUserCameraOff('user-bob'), false);

      // Verify Carol on seat 2
      final carolSeat = roomState.getSeat(2);
      expect(carolSeat, isNotNull);
      expect(carolSeat!.userId, 'user-carol');
      expect(carolSeat.isMuted, false);
      expect(carolSeat.isCameraOff, true);
      expect(roomState.isUserMuted('user-carol'), false);
      expect(roomState.isUserCameraOff('user-carol'), true);

      // Verify lookup by userId
      expect(roomState.getSeatOfUser('user-bob')?.seatIndex, 1);
      expect(roomState.getSeatOfUser('user-carol')?.seatIndex, 2);
      expect(roomState.getSeatOfUser('user-nonexistent'), isNull);

      // Verify waiting list / pending requests
      expect(roomState.pendingSeatRequests.length, 1);
      expect(roomState.pendingSeatRequests.first.requesterId, 'user-dave');
      expect(roomState.pendingSeatRequests.first.requesterName, 'Dave');
    });

    test('updateUserMediaState updates both seat copy and direct helpers', () {
      final roomState = RoomState();
      roomState.updateActiveSeats({
        '1': 'guest-1',
      });

      expect(roomState.isUserMuted('guest-1'), false);
      expect(roomState.isUserCameraOff('guest-1'), false);

      roomState.updateUserMediaState('guest-1', isMuted: true, isCameraOff: true);

      expect(roomState.isUserMuted('guest-1'), true);
      expect(roomState.isUserCameraOff('guest-1'), true);
      expect(roomState.getSeat(1)?.isMuted, true);
      expect(roomState.getSeat(1)?.isCameraOff, true);
    });
  });

  group('Customizable Builders & Widgets', () {
    late OmniCastClient client;

    setUp(() {
      client = OmniCastClient.custom(
        config: OmniCastConfig.fromServer(
          serverUrl: '127.0.0.1:8080',
          apiKey: 'test_key',
        ),
      );
    });

    tearDown(() async {
      await client.dispose();
    });

    testWidgets('OmniCastLiveRoomsBuilder gives developer 100% custom UI control', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastLiveRoomsBuilder(
              client: client,
              builder: (context, rooms) {
                return Text('Live Rooms Count: ${rooms.length}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Live Rooms Count: 0'), findsOneWidget);

      // Update room list
      client.liveRoomsNotifier.value = [
        RoomModel(
          roomId: 'room-1',
          title: 'Gaming Night',
          hostId: 'streamer-1',
          hostName: 'Streamer',
          createdAt: DateTime.now(),
          viewerCount: 15,
        ),
      ];

      await tester.pump();
      expect(find.text('Live Rooms Count: 1'), findsOneWidget);
    });

    testWidgets('OmniCastStageBuilder gives developer 100% custom stage design control', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastStageBuilder(
              client: client,
              builder: (context, seats, count) {
                return Column(
                  children: [
                    Text('Occupied Seats: $count'),
                    for (final s in seats) Text('Seat ${s.seatIndex}: ${s.userId}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Occupied Seats: 0'), findsOneWidget);

      // Host adds guest to seat
      client.state.updateActiveSeats({
        '1': 'player-one',
        '2': 'player-two',
      });

      await tester.pump();
      expect(find.text('Occupied Seats: 2'), findsOneWidget);
      expect(find.text('Seat 1: player-one'), findsOneWidget);
      expect(find.text('Seat 2: player-two'), findsOneWidget);
    });

    testWidgets('OmniCastStageGrid renders customizable seats with mic indicators', (tester) async {
      client.state.updateActiveSeats({
        '1': 'cohost-vip',
      });
      client.state.updateUserMediaState('cohost-vip', isMuted: true, isCameraOff: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastStageGrid(
              client: client,
              maxSeats: 3,
              crossAxisCount: 3,
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('cohost-vip'), findsOneWidget);
      expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
      expect(find.text('Seat 2'), findsOneWidget);
      expect(find.text('Seat 3'), findsOneWidget);
    });

    test('RoomState does not throw if reset or notifyListeners called after dispose', () {
      final state = RoomState();
      state.dispose();
      expect(state.isDisposed, true);

      // Should safely return without throwing FlutterError: A RoomState was used after being disposed
      expect(() => state.reset(), returnsNormally);
      expect(() => state.notifyListeners(), returnsNormally);
      expect(() => state.updateViewers(count: 10), returnsNormally);
      expect(() => state.dispose(), returnsNormally);
    });
  });
}
