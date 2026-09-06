import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  group('Main Seat and Dynamic Stage Tests', () {
    late RoomState roomState;

    setUp(() {
      roomState = RoomState();
    });

    test('mainSeatUserId defaults to hostId when no user is pinned', () {
      roomState.setSession(
        roomId: 'room_101',
        userId: 'host_101',
        role: UserRole.host,
      );

      expect(roomState.isHostInMainSeat, isTrue);
      expect(roomState.mainSeatUserId, 'host_101');
    });

    test('promoting co-host updates mainSeatUserId and isHostInMainSeat', () {
      roomState.setSession(
        roomId: 'room_101',
        userId: 'host_101',
        role: UserRole.host,
      );

      // Host promotes co-host_vip to Main Seat
      roomState.setPinnedStageUser('co-host_vip');

      expect(roomState.isHostInMainSeat, isFalse);
      expect(roomState.mainSeatUserId, 'co-host_vip');
      expect(roomState.pinnedStageUserId, 'co-host_vip');

      // Host restores main seat
      roomState.setPinnedStageUser(null);
      expect(roomState.isHostInMainSeat, isTrue);
      expect(roomState.mainSeatUserId, 'host_101');
    });

    test('syncRoomInfo correctly parses main_seat_id and pinned_user_id', () {
      roomState.setSession(
        roomId: 'room_101',
        userId: 'viewer_1',
        role: UserRole.viewer,
      );

      // 1. Room info with co-host as main seat
      roomState.syncRoomInfo({
        'room_id': 'room_101',
        'host_id': 'host_99',
        'main_seat_id': 'cohost_star',
      });

      expect(roomState.isHostInMainSeat, isFalse);
      expect(roomState.mainSeatUserId, 'cohost_star');

      // 2. Room info with host restored as main seat
      roomState.syncRoomInfo({
        'room_id': 'room_101',
        'host_id': 'host_99',
        'main_seat_id': 'host_99',
      });

      expect(roomState.isHostInMainSeat, isTrue);
      expect(roomState.mainSeatUserId, 'host_99');
    });
  });
}
