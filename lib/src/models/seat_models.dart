import 'room_models.dart';

/// Represents an active co-host stage seat.
class StageSeat {
  final int seatIndex;
  final String? userId;
  final Participant? user;
  final bool isLocked;
  final bool isMuted;

  const StageSeat({
    required this.seatIndex,
    this.userId,
    this.user,
    this.isLocked = false,
    this.isMuted = false,
  });

  bool get isOccupied => userId != null && userId!.isNotEmpty;

  factory StageSeat.fromJson(Map<String, dynamic> json) {
    return StageSeat(
      seatIndex: (json['seat_index'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String?,
      user: json['user'] != null
          ? Participant.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      isLocked: json['is_locked'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'seat_index': seatIndex,
        'user_id': userId,
        'user': user?.toJson(),
        'is_locked': isLocked,
        'is_muted': isMuted,
      };
}

/// Co-host invitation from the host to a viewer.
class CoHostInvite {
  final String inviteId;
  final String hostId;
  final String targetUserId;
  final int? seatIndex;
  final DateTime createdAt;

  const CoHostInvite({
    required this.inviteId,
    required this.hostId,
    required this.targetUserId,
    this.seatIndex,
    required this.createdAt,
  });

  factory CoHostInvite.fromJson(Map<String, dynamic> json) {
    return CoHostInvite(
      inviteId: json['invite_id'] as String? ?? '',
      hostId: json['host_id'] as String? ?? '',
      targetUserId: json['target_user_id'] as String? ?? '',
      seatIndex: (json['seat_index'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'invite_id': inviteId,
        'host_id': hostId,
        'target_user_id': targetUserId,
        'seat_index': seatIndex,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Viewer's request to take a co-host seat on stage.
class SeatRequest {
  final String requesterId;
  final String? requesterName;
  final String? requesterAvatar;
  final int? preferredSeatIndex;
  final DateTime requestedAt;

  const SeatRequest({
    required this.requesterId,
    this.requesterName,
    this.requesterAvatar,
    this.preferredSeatIndex,
    required this.requestedAt,
  });

  factory SeatRequest.fromJson(Map<String, dynamic> json) {
    return SeatRequest(
      requesterId: json['requester_id'] as String? ?? json['user_id'] as String? ?? '',
      requesterName: json['requester_name'] as String?,
      requesterAvatar: json['requester_avatar'] as String?,
      preferredSeatIndex: (json['preferred_seat_index'] as num?)?.toInt(),
      requestedAt: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'requester_id': requesterId,
        'requester_name': requesterName,
        'requester_avatar': requesterAvatar,
        'preferred_seat_index': preferredSeatIndex,
        'timestamp': requestedAt.toIso8601String(),
      };
}
