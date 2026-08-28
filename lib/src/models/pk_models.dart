/// Lifecycle status of a host PK battle.
enum PKStatus {
  idle,
  requested,
  matched,
  inProgress,
  punishment,
  ended,
}

/// Information describing an active PK host battle across two rooms.
class PKBattleInfo {
  final String battleId;
  final String hostRoomId;
  final String hostUserId;
  final String opponentRoomId;
  final String opponentUserId;
  final String? opponentDisplayName;
  final String? opponentAvatarUrl;
  final PKStatus status;
  final int hostScore;
  final int opponentScore;
  final int durationSeconds;
  final int remainingSeconds;
  final DateTime startedAt;

  const PKBattleInfo({
    required this.battleId,
    required this.hostRoomId,
    required this.hostUserId,
    required this.opponentRoomId,
    required this.opponentUserId,
    this.opponentDisplayName,
    this.opponentAvatarUrl,
    this.status = PKStatus.inProgress,
    this.hostScore = 0,
    this.opponentScore = 0,
    this.durationSeconds = 300,
    this.remainingSeconds = 300,
    required this.startedAt,
  });

  factory PKBattleInfo.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'in_progress';
    final status = switch (statusStr.toLowerCase()) {
      'requested' => PKStatus.requested,
      'matched' => PKStatus.matched,
      'in_progress' || 'inprogress' => PKStatus.inProgress,
      'punishment' => PKStatus.punishment,
      'ended' => PKStatus.ended,
      _ => PKStatus.idle,
    };

    return PKBattleInfo(
      battleId: json['battle_id'] as String? ?? '',
      hostRoomId: json['host_room_id'] as String? ?? '',
      hostUserId: json['host_user_id'] as String? ?? '',
      opponentRoomId: json['opponent_room_id'] as String? ?? '',
      opponentUserId: json['opponent_user_id'] as String? ?? '',
      opponentDisplayName: json['opponent_display_name'] as String?,
      opponentAvatarUrl: json['opponent_avatar_url'] as String?,
      status: status,
      hostScore: (json['host_score'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponent_score'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 300,
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 300,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'battle_id': battleId,
        'host_room_id': hostRoomId,
        'host_user_id': hostUserId,
        'opponent_room_id': opponentRoomId,
        'opponent_user_id': opponentUserId,
        'opponent_display_name': opponentDisplayName,
        'opponent_avatar_url': opponentAvatarUrl,
        'status': status.name,
        'host_score': hostScore,
        'opponent_score': opponentScore,
        'duration_seconds': durationSeconds,
        'remaining_seconds': remainingSeconds,
        'started_at': startedAt.toIso8601String(),
      };
}

/// Real-time PK score update event.
class PKScoreUpdate {
  final String battleId;
  final int hostScore;
  final int opponentScore;
  final String? lastGiftSenderId;
  final int? deltaPoints;

  const PKScoreUpdate({
    required this.battleId,
    required this.hostScore,
    required this.opponentScore,
    this.lastGiftSenderId,
    this.deltaPoints,
  });

  factory PKScoreUpdate.fromJson(Map<String, dynamic> json) {
    return PKScoreUpdate(
      battleId: json['battle_id'] as String? ?? '',
      hostScore: (json['host_score'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponent_score'] as num?)?.toInt() ?? 0,
      lastGiftSenderId: json['last_gift_sender_id'] as String?,
      deltaPoints: (json['delta_points'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'battle_id': battleId,
        'host_score': hostScore,
        'opponent_score': opponentScore,
        'last_gift_sender_id': lastGiftSenderId,
        'delta_points': deltaPoints,
      };
}

/// Periodic PK timer tick event.
class PKTimerTick {
  final String battleId;
  final int remainingSeconds;
  final bool isPunishmentPhase;

  const PKTimerTick({
    required this.battleId,
    required this.remainingSeconds,
    this.isPunishmentPhase = false,
  });

  factory PKTimerTick.fromJson(Map<String, dynamic> json) {
    return PKTimerTick(
      battleId: json['battle_id'] as String? ?? '',
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 0,
      isPunishmentPhase: json['is_punishment_phase'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'battle_id': battleId,
        'remaining_seconds': remainingSeconds,
        'is_punishment_phase': isPunishmentPhase,
      };
}
