import 'dart:convert';

/// Represents a standardized signaling message envelope for the OmniCast SFU protocol.
///
/// Follows the JSON contract:
/// ```json
/// {
///   "event": "string",
///   "room_id": "string",
///   "user_id": "string",
///   "target_user": "string (optional)",
///   "payload": "dynamic/object"
/// }
/// ```
class SignalingMessage {
  final String event;
  final String roomId;
  final String userId;
  final String? targetUser;
  final dynamic payload;

  const SignalingMessage({
    required this.event,
    required this.roomId,
    required this.userId,
    this.targetUser,
    this.payload,
  });

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      event: json['event'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      targetUser: json['target_user'] as String?,
      payload: json['payload'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'event': event,
      'room_id': roomId,
      'user_id': userId,
    };
    if (targetUser != null && targetUser!.isNotEmpty) {
      map['target_user'] = targetUser;
    }
    if (payload != null) {
      map['payload'] = payload;
    }
    return map;
  }

  String serialize() => jsonEncode(toJson());

  static SignalingMessage? tryDeserialize(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return SignalingMessage.fromJson(decoded);
      }
    } catch (_) {
      // Ignored: Invalid JSON string
    }
    return null;
  }

  @override
  String toString() =>
      'SignalingMessage(event: $event, roomId: $roomId, userId: $userId, targetUser: $targetUser, payload: $payload)';
}

/// Constants defining supported signaling protocol event names.
abstract final class SignalingEvents {
  // WebRTC SDP & ICE
  static const String offer = 'offer';
  static const String sdpOffer = 'sdp_offer';
  static const String answer = 'answer';
  static const String sdpAnswer = 'sdp_answer';
  static const String ice = 'ice';
  static const String candidate = 'candidate';

  // Room Actions & Lifecycle
  static const String createRoom = 'create_room';
  static const String joinRoom = 'join_room';
  static const String publish = 'publish';
  static const String leaveRoom = 'leave_room';
  static const String kickUser = 'kick_user';
  static const String ping = 'ping';
  static const String pong = 'pong';

  // State Sync
  static const String roomInfoSync = 'room_info_sync';
  static const String viewerUpdate = 'viewer_update';

  // Social & Interactive Events
  static const String chat = 'chat';
  static const String giftProcessed = 'gift_processed';
  static const String balanceUpdate = 'balance_update';

  // Seat & Stage Management
  static const String seatRequest = 'seat_request';
  static const String seatAccept = 'seat_accept';
  static const String seatReject = 'seat_reject';
  static const String seatInvite = 'seat_invite';
  static const String seatKick = 'seat_kick';
  static const String seatLeave = 'seat_leave';
  static const String pinStage = 'pin_stage';

  // PK Battle System
  static const String pkRequest = 'pk_request';
  static const String pkAccept = 'pk_accept';
  static const String pkReject = 'pk_reject';
  static const String pkStart = 'pk_start';
  static const String pkScoreUpdate = 'pk_score_update';
  static const String pkTimerTick = 'pk_timer_tick';
  static const String pkEnd = 'pk_end';

  // Media & Dynacast Controls
  static const String layerSelect = 'layer_select';
  static const String trackPause = 'track_pause';
  static const String trackResume = 'track_resume';
}
