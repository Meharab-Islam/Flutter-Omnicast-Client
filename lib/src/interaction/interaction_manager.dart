import 'dart:async';
import '../models/interaction_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';

/// Manages live interactions: sending/receiving chat messages, sending gifts,
/// and streaming gift and coin balance updates.
class InteractionManager {
  final SignalingClient _signalingClient;
  final RoomState _roomState;

  final _giftReceivedController = StreamController<GiftEvent>.broadcast();
  final _balanceUpdatedController = StreamController<BalanceUpdate>.broadcast();

  InteractionManager({
    required SignalingClient signalingClient,
    required RoomState roomState,
  })  : _signalingClient = signalingClient,
        _roomState = roomState {
    _bindStreams();
  }

  Stream<GiftEvent> get onGiftReceived => _giftReceivedController.stream;
  Stream<BalanceUpdate> get onBalanceUpdated => _balanceUpdatedController.stream;

  void _bindStreams() {
    _signalingClient.onGift.listen((gift) {
      _giftReceivedController.add(gift);
      _roomState.processGift(gift);
    });

    _signalingClient.onMessage.listen((msg) {
      if (msg.event == SignalingEvents.balanceUpdate && msg.payload is Map<String, dynamic>) {
        final update = BalanceUpdate.fromJson(msg.payload as Map<String, dynamic>);
        _balanceUpdatedController.add(update);
        _roomState.updateBalance(update);
      }
    });
  }

  /// Sends a real-time chat message to the room.
  void sendChat(String text) {
    if (!_roomState.isInRoom) return;

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _roomState.userId!,
      senderName: _roomState.userId!,
      text: text,
      timestamp: DateTime.now(),
    );

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.chat,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      payload: msg.toJson(),
    ));

    _roomState.addChatMessage(msg);
  }

  /// Sends a gift to the room host or a specific co-host [targetUserId].
  void sendGift({
    required String giftId,
    required int amount,
    String? targetUserId,
    String giftName = 'Gift',
    int coinValue = 0,
  }) {
    if (!_roomState.isInRoom) return;

    final giftEvent = GiftEvent(
      giftId: giftId,
      giftName: giftName,
      senderId: _roomState.userId!,
      senderName: _roomState.userId!,
      targetUserId: targetUserId ?? _roomState.hostId,
      amount: amount,
      coinValue: coinValue,
      hostTotalCoins: _roomState.hostCoinBalance + (coinValue * amount),
      timestamp: DateTime.now(),
    );

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.giftProcessed,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      targetUser: targetUserId,
      payload: giftEvent.toJson(),
    ));
  }

  /// Disposes internal controllers.
  Future<void> dispose() async {
    await _giftReceivedController.close();
    await _balanceUpdatedController.close();
  }
}
