import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  group('RoomState', () {
    late RoomState roomState;

    setUp(() {
      roomState = RoomState();
    });

    test('initial state is correct', () {
      expect(roomState.roomId, isNull);
      expect(roomState.userId, isNull);
      expect(roomState.role, UserRole.viewer);
      expect(roomState.connectionState, ClientConnectionState.disconnected);
      expect(roomState.viewersCount, 0);
      expect(roomState.hostCoinBalance, 0);
      expect(roomState.chatHistory, isEmpty);
      expect(roomState.activeRemoteUserIds, isEmpty);
      expect(roomState.isInRoom, isFalse);
      expect(roomState.isInPKBattle, isFalse);
    });

    test('updates session and notifies listeners', () {
      var notified = false;
      roomState.addListener(() => notified = true);

      roomState.setSession(
        roomId: 'room_abc',
        userId: 'user_123',
        role: UserRole.host,
      );

      expect(roomState.roomId, 'room_abc');
      expect(roomState.userId, 'user_123');
      expect(roomState.role, UserRole.host);
      expect(roomState.isHost, isTrue);
      expect(roomState.isInRoom, isTrue);
      expect(notified, isTrue);
    });

    test('handles chat messages and truncates above capacity', () {
      for (var i = 0; i < 210; i++) {
        roomState.addChatMessage(ChatMessage(
          id: 'msg_$i',
          senderId: 'user_$i',
          senderName: 'User $i',
          text: 'Message $i',
          timestamp: DateTime.now(),
        ));
      }

      expect(roomState.chatHistory.length, 200);
      expect(roomState.chatHistory.first.id, 'msg_10');
      expect(roomState.chatHistory.last.id, 'msg_209');
    });

    test('syncs late-join room_info_sync data', () {
      final now = DateTime.now();
      roomState.syncRoomInfo({
        'room_id': 'room_late',
        'host_id': 'host_10',
        'viewers_count': 42,
        'host_coin_balance': 9999,
        'pinned_user_id': 'vip_cohost',
        'active_pk': {
          'battle_id': 'pk_99',
          'host_room_id': 'room_late',
          'host_user_id': 'host_10',
          'opponent_room_id': 'room_other',
          'opponent_user_id': 'opponent_20',
          'host_score': 100,
          'opponent_score': 80,
          'started_at': now.toIso8601String(),
        },
      });

      expect(roomState.roomId, 'room_late');
      expect(roomState.hostId, 'host_10');
      expect(roomState.viewersCount, 42);
      expect(roomState.hostCoinBalance, 9999);
      expect(roomState.pinnedStageUserId, 'vip_cohost');
      expect(roomState.isInPKBattle, isTrue);
      expect(roomState.activePK?.battleId, 'pk_99');
      expect(roomState.activeRemoteUserIds.contains('opponent_20'), isTrue);
    });

    test('resets all state when leaving room', () {
      roomState.setSession(
        roomId: 'room_1',
        userId: 'user_1',
        role: UserRole.host,
      );
      roomState.addActiveRemoteUser('peer_1');
      roomState.addChatMessage(ChatMessage(
        id: '1',
        senderId: 'user_1',
        senderName: 'Host',
        text: 'Hi',
        timestamp: DateTime.now(),
      ));

      roomState.reset();

      expect(roomState.roomId, isNull);
      expect(roomState.userId, isNull);
      expect(roomState.isInRoom, isFalse);
      expect(roomState.chatHistory, isEmpty);
      expect(roomState.activeRemoteUserIds, isEmpty);
    });
  });
}
