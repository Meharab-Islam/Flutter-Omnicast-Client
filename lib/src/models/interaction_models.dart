/// Real-time chat message sent or received in the live room.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final int senderLevel;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    this.senderLevel = 1,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic val) {
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val);
      } else if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['sender_id'] as String? ?? json['user_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? json['user_name'] as String? ?? 'Anonymous',
      senderAvatar: json['sender_avatar'] as String?,
      text: json['text'] as String? ?? json['message'] as String? ?? '',
      senderLevel: (json['sender_level'] as num?)?.toInt() ?? 1,
      timestamp: parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'text': text,
        'sender_level': senderLevel,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Gift transaction event processed in the live room.
class GiftEvent {
  final String giftId;
  final String giftName;
  final String? giftIconUrl;
  final String senderId;
  final String senderName;
  final String? targetUserId;
  final int amount;
  final int coinValue;
  final int hostTotalCoins;
  final DateTime timestamp;

  const GiftEvent({
    required this.giftId,
    required this.giftName,
    this.giftIconUrl,
    required this.senderId,
    required this.senderName,
    this.targetUserId,
    required this.amount,
    required this.coinValue,
    required this.hostTotalCoins,
    required this.timestamp,
  });

  factory GiftEvent.fromJson(Map<String, dynamic> json) {
    return GiftEvent(
      giftId: json['gift_id'] as String? ?? '',
      giftName: json['gift_name'] as String? ?? 'Gift',
      giftIconUrl: json['gift_icon_url'] as String?,
      senderId: json['sender_id'] as String? ?? json['user_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? 'Anonymous',
      targetUserId: json['target_user_id'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 1,
      coinValue: (json['coin_value'] as num?)?.toInt() ?? 0,
      hostTotalCoins: (json['host_total_coins'] as num?)?.toInt() ??
          (json['host_coin_balance'] as num?)?.toInt() ??
          0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'gift_id': giftId,
        'gift_name': giftName,
        'gift_icon_url': giftIconUrl,
        'sender_id': senderId,
        'sender_name': senderName,
        'target_user_id': targetUserId,
        'amount': amount,
        'coin_value': coinValue,
        'host_total_coins': hostTotalCoins,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Coin balance update event for the user or host.
class BalanceUpdate {
  final String userId;
  final int newBalance;
  final int delta;
  final String reason;

  const BalanceUpdate({
    required this.userId,
    required this.newBalance,
    required this.delta,
    required this.reason,
  });

  factory BalanceUpdate.fromJson(Map<String, dynamic> json) {
    return BalanceUpdate(
      userId: json['user_id'] as String? ?? '',
      newBalance: (json['new_balance'] as num?)?.toInt() ??
          (json['balance'] as num?)?.toInt() ??
          0,
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? 'gift',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'new_balance': newBalance,
        'delta': delta,
        'reason': reason,
      };
}
