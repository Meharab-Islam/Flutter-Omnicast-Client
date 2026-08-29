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
