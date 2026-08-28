/// Lifecycle status of a host PK battle.
enum PKStatus {
  idle,
  requested,
  matched,
  inProgress,
  punishment,
  ended,
}

/// Reactive snapshot representing the current PK battle state.
class PKState {
  final bool isPKActive;
  final String? battleId;
  final String? hostRoomId;
  final String? hostUserId;
  final String? opponentRoomId;
  final String? opponentUserId;
  final String? opponentDisplayName;
  final String? opponentAvatarUrl;
  final int myScore;
  final int opponentScore;
  final int remainingSeconds;
  final int durationSeconds;
  final PKStatus status;
  final bool isPunishmentPhase;

  const PKState({
    this.isPKActive = false,
    this.battleId,
    this.hostRoomId,
    this.hostUserId,
    this.opponentRoomId,
    this.opponentUserId,
    this.opponentDisplayName,
    this.opponentAvatarUrl,
    this.myScore = 0,
    this.opponentScore = 0,
    this.remainingSeconds = 300,
    this.durationSeconds = 300,
    this.status = PKStatus.idle,
    this.isPunishmentPhase = false,
  });

  /// Idle / initial inactive state.
  static const PKState idle = PKState();

  /// Total combined points/coins accumulated in the battle.
  int get totalScore => myScore + opponentScore;

  /// Normalized host score ratio between 0.05 and 0.95 for visual progress bars.
  double get hostScoreRatio {
    if (totalScore == 0) return 0.5;
    final ratio = myScore / totalScore;
    return ratio.clamp(0.05, 0.95);
  }

  /// Normalized opponent score ratio.
  double get opponentScoreRatio => 1.0 - hostScoreRatio;

  bool get isWinning => myScore > opponentScore;
  bool get isLosing => myScore < opponentScore;
  bool get isTied => myScore == opponentScore;

  Duration get remainingTime => Duration(seconds: remainingSeconds);

  factory PKState.fromBattleInfo(PKBattleInfo info, {String? currentUserId}) {
    final isHost = currentUserId == null || currentUserId == info.hostUserId;
    return PKState(
      isPKActive: info.status == PKStatus.inProgress || info.status == PKStatus.punishment,
      battleId: info.battleId,
      hostRoomId: info.hostRoomId,
      hostUserId: info.hostUserId,
      opponentRoomId: info.opponentRoomId,
      opponentUserId: info.opponentUserId,
      opponentDisplayName: info.opponentDisplayName,
      opponentAvatarUrl: info.opponentAvatarUrl,
      myScore: isHost ? info.hostScore : info.opponentScore,
      opponentScore: isHost ? info.opponentScore : info.hostScore,
      remainingSeconds: info.remainingSeconds,
      durationSeconds: info.durationSeconds,
      status: info.status,
      isPunishmentPhase: info.status == PKStatus.punishment,
    );
  }

  PKState copyWith({
    bool? isPKActive,
    String? battleId,
    String? hostRoomId,
    String? hostUserId,
    String? opponentRoomId,
    String? opponentUserId,
    String? opponentDisplayName,
    String? opponentAvatarUrl,
    int? myScore,
    int? opponentScore,
    int? remainingSeconds,
    int? durationSeconds,
    PKStatus? status,
    bool? isPunishmentPhase,
  }) {
    return PKState(
      isPKActive: isPKActive ?? this.isPKActive,
      battleId: battleId ?? this.battleId,
      hostRoomId: hostRoomId ?? this.hostRoomId,
      hostUserId: hostUserId ?? this.hostUserId,
      opponentRoomId: opponentRoomId ?? this.opponentRoomId,
      opponentUserId: opponentUserId ?? this.opponentUserId,
      opponentDisplayName: opponentDisplayName ?? this.opponentDisplayName,
      opponentAvatarUrl: opponentAvatarUrl ?? this.opponentAvatarUrl,
      myScore: myScore ?? this.myScore,
      opponentScore: opponentScore ?? this.opponentScore,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      isPunishmentPhase: isPunishmentPhase ?? this.isPunishmentPhase,
    );
  }
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
