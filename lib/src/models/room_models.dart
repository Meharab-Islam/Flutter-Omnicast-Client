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
  final Map<String, dynamic>? metadata;

  const RoomOptions({
    this.title = 'Live Stream',
    this.roomType = RoomType.video,
    this.enableAudio = true,
    this.enableVideo = true,
    this.enableSimulcast = true,
    this.enableDynacast = true,
    this.maxCoHosts = 4,
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
    final meta = rawMeta is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMeta)
        : (rawMeta is Map
            ? Map<String, dynamic>.from(rawMeta)
            : const <String, dynamic>{});

    return OmniCastParticipant(
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['name'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatar'] as String?,
      role: role,
      isAudioMuted: json['is_audio_muted'] as bool? ?? false,
      isVideoMuted: json['is_video_muted'] as bool? ?? false,
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

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['room_type'] as String? ?? json['type'] as String? ?? 'video';

    final rawMeta = json['metadata'];
    final meta = rawMeta is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMeta)
        : (rawMeta is Map
            ? Map<String, dynamic>.from(rawMeta)
            : const <String, dynamic>{});

    return RoomModel(
      roomId: json['room_id'] as String? ?? json['roomId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['room_title'] as String? ?? meta['title'] as String? ?? 'Live Broadcast',
      hostId: json['host_id'] as String? ?? json['hostId'] as String? ?? 'Host',
      hostName: json['host_name'] as String? ?? json['hostDisplayName'] as String? ?? meta['displayName'] as String? ?? 'Broadcaster',
      hostAvatar: json['host_avatar'] as String? ?? json['avatarUrl'] as String? ?? meta['avatar'] as String?,
      roomType: typeStr.toLowerCase() == 'audio' ? RoomType.audio : RoomType.video,
      viewerCount: (json['viewer_count'] as num?)?.toInt() ??
          (json['viewers_count'] as num?)?.toInt() ??
          (json['total_viewers'] as num?)?.toInt() ??
          0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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

