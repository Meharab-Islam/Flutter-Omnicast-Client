import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  group('SignalingMessage Serialization & Deserialization', () {
    test('serializes and deserializes correctly with payload', () {
      const msg = SignalingMessage(
        event: SignalingEvents.offer,
        roomId: 'room_101',
        userId: 'user_42',
        targetUser: 'user_99',
        payload: {'sdp': 'v=0\r\no=...', 'type': 'offer'},
      );

      final jsonStr = msg.serialize();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['event'], 'offer');
      expect(decoded['room_id'], 'room_101');
      expect(decoded['user_id'], 'user_42');
      expect(decoded['target_user'], 'user_99');
      expect(decoded['payload']['type'], 'offer');

      final parsed = SignalingMessage.tryDeserialize(jsonStr);
      expect(parsed, isNotNull);
      expect(parsed!.event, SignalingEvents.offer);
      expect(parsed.roomId, 'room_101');
      expect(parsed.userId, 'user_42');
      expect(parsed.targetUser, 'user_99');
      expect(parsed.payload['sdp'], 'v=0\r\no=...');
    });

    test('deserializes messages without optional targetUser or payload', () {
      const rawJson = '{"event":"leave_room","room_id":"room_1","user_id":"user_2"}';
      final parsed = SignalingMessage.tryDeserialize(rawJson);

      expect(parsed, isNotNull);
      expect(parsed!.event, SignalingEvents.leaveRoom);
      expect(parsed.roomId, 'room_1');
      expect(parsed.userId, 'user_2');
      expect(parsed.targetUser, isNull);
      expect(parsed.payload, isNull);
    });

    test('returns null when deserializing malformed json', () {
      expect(SignalingMessage.tryDeserialize('invalid_json_string'), isNull);
      expect(SignalingMessage.tryDeserialize('12345'), isNull);
    });
  });

  group('Interaction & PK Models', () {
    test('ChatMessage json serialization', () {
      final now = DateTime.now();
      final chat = ChatMessage(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alice',
        text: 'Hello OmniCast!',
        timestamp: now,
      );

      final json = chat.toJson();
      final parsed = ChatMessage.fromJson(json);

      expect(parsed.id, 'msg_1');
      expect(parsed.senderId, 'user_1');
      expect(parsed.senderName, 'Alice');
      expect(parsed.text, 'Hello OmniCast!');
      expect(parsed.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('GiftEvent json serialization', () {
      final now = DateTime.now();
      final gift = GiftEvent(
        giftId: 'rocket_99',
        giftName: 'Space Rocket',
        senderId: 'user_1',
        senderName: 'Bob',
        amount: 50,
        coinValue: 10,
        hostTotalCoins: 2500,
        timestamp: now,
      );

      final json = gift.toJson();
      final parsed = GiftEvent.fromJson(json);

      expect(parsed.giftId, 'rocket_99');
      expect(parsed.giftName, 'Space Rocket');
      expect(parsed.amount, 50);
      expect(parsed.coinValue, 10);
      expect(parsed.hostTotalCoins, 2500);
    });

    test('PKBattleInfo json serialization', () {
      final now = DateTime.now();
      final pk = PKBattleInfo(
        battleId: 'pk_123',
        hostRoomId: 'room_1',
        hostUserId: 'host_1',
        opponentRoomId: 'room_2',
        opponentUserId: 'host_2',
        opponentDisplayName: 'Opponent Star',
        hostScore: 500,
        opponentScore: 350,
        startedAt: now,
      );

      final json = pk.toJson();
      final parsed = PKBattleInfo.fromJson(json);

      expect(parsed.battleId, 'pk_123');
      expect(parsed.opponentDisplayName, 'Opponent Star');
      expect(parsed.hostScore, 500);
      expect(parsed.opponentScore, 350);
      expect(parsed.status, PKStatus.inProgress);
    });
  });
}
