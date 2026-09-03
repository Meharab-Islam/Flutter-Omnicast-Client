/// Room broadcasting modality (Video vs. Audio-Only).
enum RoomType {
  video,
  audio,
}

/// High-level layout and broadcast state mode.
enum RoomMode {
  solo,
  coHost,
  pk,
}

/// Real-time Host vs Opponent PK Battle score points.
class PkScore {
  final int hostScore;
  final int opponentScore;

  const PkScore({
    this.hostScore = 0,
    this.opponentScore = 0,
  });

  double get hostRatio {
    final total = hostScore + opponentScore;
    if (total == 0) return 0.5;
    return (hostScore / total).clamp(0.05, 0.95);
  }

  double get opponentRatio {
    final total = hostScore + opponentScore;
    if (total == 0) return 0.5;
    return (opponentScore / total).clamp(0.05, 0.95);
  }
}

/// User role in a live room session.
enum UserRole {
  viewer,
  host,
  coHost,
}

/// Connection lifecycle state of the SDK client.
enum ClientConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Options passed when creating a new live broadcasting room.
class RoomOptions {
  final String title;
  final RoomType roomType;
  final bool enableAudio;
  final bool enableVideo;
  final bool enableSimulcast;
  final bool enableDynacast;
  final int maxCoHosts;
  final bool showJoinMessages;
  final Map<String, dynamic>? metadata;

  const RoomOptions({
    this.title = 'Live Stream',
    this.roomType = RoomType.video,
    this.enableAudio = true,
    this.enableVideo = true,
    this.enableSimulcast = true,
    this.enableDynacast = true,
    this.maxCoHosts = 4,
    this.showJoinMessages = true,
    this.metadata,
  });

  bool get isAudioOnly => roomType == RoomType.audio;

  Map<String, dynamic> toJson() => {
        'title': title,
        'room_type': roomType.name,
        'enable_audio': enableAudio,
        'enable_video': isAudioOnly ? false : enableVideo,
        'enable_simulcast': isAudioOnly ? false : enableSimulcast,
        'enable_dynacast': enableDynacast,
        'max_co_hosts': maxCoHosts,
        'show_join_messages': showJoinMessages,
        'metadata': ?metadata,
      };

  factory RoomOptions.fromJson(Map<String, dynamic> json) {
    final typeStr = json['room_type'] as String? ?? 'video';
    final roomType = typeStr.toLowerCase() == 'audio' ? RoomType.audio : RoomType.video;

    return RoomOptions(
      title: json['title'] as String? ?? 'Live Stream',
      roomType: roomType,
      enableAudio: json['enable_audio'] as bool? ?? true,
      enableVideo: roomType == RoomType.audio ? false : (json['enable_video'] as bool? ?? true),
      enableSimulcast: roomType == RoomType.audio ? false : (json['enable_simulcast'] as bool? ?? true),
      enableDynacast: json['enable_dynacast'] as bool? ?? true,
      maxCoHosts: (json['max_co_hosts'] as num?)?.toInt() ?? 4,
      showJoinMessages: json['show_join_messages'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Information describing a participant / live viewer inside an OmniCast room.
class OmniCastParticipant {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final UserRole role;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final DateTime joinedAt;
  final Map<String, dynamic> metadata;

  const OmniCastParticipant({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.role = UserRole.viewer,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    required this.joinedAt,
    this.metadata = const {},
  });

  factory OmniCastParticipant.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'viewer';
    final role = switch (roleStr.toLowerCase()) {
      'host' => UserRole.host,
      'co_host' || 'cohost' => UserRole.coHost,
      _ => UserRole.viewer,
    };

    final rawMeta = json['metadata'];
    final meta = <String, dynamic>{};
    if (rawMeta is Map) {
      meta.addAll(Map<String, dynamic>.from(rawMeta));
    }
    if (json['level'] != null) meta['level'] = json['level'];
    if (json['is_vip'] != null) meta['is_vip'] = json['is_vip'];
    if (json['isVip'] != null) meta['is_vip'] = json['isVip'];
    if (json['badge'] != null) meta['badge'] = json['badge'];

    final userId = (json['user_id'] ?? json['userId'] ?? json['id'] ?? json['sub'] ?? '').toString();
    final displayName = (json['display_name'] ??
            json['displayName'] ??
            json['user_name'] ??
            json['userName'] ??
            json['name'] ??
            json['nickname'])
        ?.toString();
    final avatarUrl = (json['avatar_url'] ??
            json['avatarUrl'] ??
            json['avatar'] ??
            json['profile_pic'] ??
            json['image'])
        ?.toString();

    return OmniCastParticipant(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role,
      isAudioMuted: json['is_audio_muted'] as bool? ?? json['is_muted'] as bool? ?? false,
      isVideoMuted: json['is_video_muted'] as bool? ?? json['is_camera_off'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'role': role.name,
        'is_audio_muted': isAudioMuted,
        'is_video_muted': isVideoMuted,
        'joined_at': joinedAt.toIso8601String(),
        'metadata': metadata,
      };

  OmniCastParticipant copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    UserRole? role,
    bool? isAudioMuted,
    bool? isVideoMuted,
    DateTime? joinedAt,
    Map<String, dynamic>? metadata,
  }) {
    return OmniCastParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      joinedAt: joinedAt ?? this.joinedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OmniCastParticipant &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

/// Backward compatibility alias for [OmniCastParticipant].
typedef Participant = OmniCastParticipant;

/// Represents an active live broadcasting room on the server.
class RoomModel {
  final String roomId;
  final String title;
  final String hostId;
  final String hostName;
  final String? hostAvatar;
  final RoomType roomType;
  final int viewerCount;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const RoomModel({
    required this.roomId,
    required this.title,
    required this.hostId,
    required this.hostName,
    this.hostAvatar,
    this.roomType = RoomType.video,
    this.viewerCount = 0,
    required this.createdAt,
    this.metadata = const {},
  });

  /// Alias for stream title.
  String get roomName => title;

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract nested metadata or options if present
    final meta = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : (json['options'] is Map<String, dynamic>
            ? json['options'] as Map<String, dynamic>
            : <String, dynamic>{});

    // 2. Extract host sub-object if present
    final hostMap = json['host'] is Map<String, dynamic>
        ? json['host'] as Map<String, dynamic>
        : (json['owner'] is Map<String, dynamic>
            ? json['owner'] as Map<String, dynamic>
            : <String, dynamic>{});

    // 3. Room ID (Supports snake_case, camelCase, id, name)
    final roomId = json['room_id']?.toString() ??
        json['roomId']?.toString() ??
        json['id']?.toString() ??
        json['channel_id']?.toString() ??
        json['name']?.toString() ??
        '';

    // 4. Stream Title
    final title = json['room_name']?.toString() ??
        json['title']?.toString() ??
        json['room_title']?.toString() ??
        json['roomTitle']?.toString() ??
        meta['title']?.toString() ??
        json['name']?.toString() ??
        (roomId.isNotEmpty ? roomId : 'Live Broadcast');

    // 5. Host ID & Name
    final hostId = json['host_id']?.toString() ??
        json['hostId']?.toString() ??
        json['user_id']?.toString() ??
        json['userId']?.toString() ??
        hostMap['id']?.toString() ??
        hostMap['user_id']?.toString() ??
        'Host';

    final hostName = json['host_name']?.toString() ??
        json['hostDisplayName']?.toString() ??
        json['host_display_name']?.toString() ??
        meta['displayName']?.toString() ??
        meta['display_name']?.toString() ??
        meta['name']?.toString() ??
        hostMap['display_name']?.toString() ??
        hostMap['name']?.toString() ??
        (hostId.isNotEmpty ? hostId : 'Broadcaster');

    // 6. Host Avatar
    final hostAvatar = json['host_avatar']?.toString() ??
        json['hostAvatar']?.toString() ??
        json['avatar_url']?.toString() ??
        json['avatarUrl']?.toString() ??
        json['avatar']?.toString() ??
        meta['avatar']?.toString() ??
        meta['avatar_url']?.toString() ??
        hostMap['avatar']?.toString() ??
        hostMap['avatar_url']?.toString();

    // 7. Room Type (Video vs Audio)
    final typeStr = json['room_type']?.toString() ??
        json['roomType']?.toString() ??
        json['type']?.toString() ??
        meta['room_type']?.toString() ??
        'video';
    final roomType =
        typeStr.toLowerCase() == 'audio' ? RoomType.audio : RoomType.video;

    // 8. Viewer Count (Supports int, double, string number, or viewers/participants list length)
    int viewerCount = 0;
    if (json['viewer_count'] != null) {
      viewerCount = int.tryParse(json['viewer_count'].toString()) ?? 0;
    } else if (json['viewers_count'] != null) {
      viewerCount = int.tryParse(json['viewers_count'].toString()) ?? 0;
    } else if (json['total_viewers'] != null) {
      viewerCount = int.tryParse(json['total_viewers'].toString()) ?? 0;
    } else if (json['viewerCount'] != null) {
      viewerCount = int.tryParse(json['viewerCount'].toString()) ?? 0;
    } else if (json['viewers'] is List) {
      viewerCount = (json['viewers'] as List).length;
    } else if (json['participants'] is List) {
      viewerCount = (json['participants'] as List).length;
    }

    // 9. Created At
    DateTime createdAt = DateTime.now();
    final rawDate = json['created_at'] ?? json['createdAt'] ?? json['timestamp'];
    if (rawDate != null) {
      if (rawDate is int) {
        createdAt = rawDate > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(rawDate)
            : DateTime.fromMillisecondsSinceEpoch(rawDate * 1000);
      } else {
        createdAt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
    }

    return RoomModel(
      roomId: roomId,
      title: title,
      hostId: hostId,
      hostName: hostName,
      hostAvatar: hostAvatar,
      roomType: roomType,
      viewerCount: viewerCount,
      createdAt: createdAt,
      metadata: meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'title': title,
        'host_id': hostId,
        'host_name': hostName,
        'host_avatar': hostAvatar,
        'room_type': roomType.name,
        'viewer_count': viewerCount,
        'created_at': createdAt.toIso8601String(),
        'metadata': metadata,
      };
}

/// Backward compatibility alias for [RoomModel].
typedef ActiveLiveRoom = RoomModel;

/// Represents a room kick/ejection event dispatched when a user is forcefully removed.
class KickedEvent {
  final String roomId;
  final String userId;
  final String? reason;
  final String? kickedBy;
  final DateTime timestamp;

  const KickedEvent({
    required this.roomId,
    required this.userId,
    this.reason,
    this.kickedBy,
    required this.timestamp,
  });

  factory KickedEvent.fromJson(Map<String, dynamic> json, {String? defaultRoomId, String? defaultUserId}) {
    return KickedEvent(
      roomId: json['room_id'] as String? ?? json['roomId'] as String? ?? defaultRoomId ?? '',
      userId: json['target_user'] as String? ?? json['user_id'] as String? ?? json['userId'] as String? ?? defaultUserId ?? '',
      reason: json['reason'] as String? ?? json['message'] as String?,
      kickedBy: json['kicked_by'] as String? ?? json['host_id'] as String?,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'user_id': userId,
        'reason': reason,
        'kicked_by': kickedBy,
        'timestamp': timestamp.toIso8601String(),
      };
}

