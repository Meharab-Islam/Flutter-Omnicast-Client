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
  final bool enableAudio;
  final bool enableVideo;
  final bool enableSimulcast;
  final bool enableDynacast;
  final int maxCoHosts;
  final Map<String, dynamic>? metadata;

  const RoomOptions({
    this.title = 'Live Stream',
    this.enableAudio = true,
    this.enableVideo = true,
    this.enableSimulcast = true,
    this.enableDynacast = true,
    this.maxCoHosts = 4,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'enable_audio': enableAudio,
        'enable_video': enableVideo,
        'enable_simulcast': enableSimulcast,
        'enable_dynacast': enableDynacast,
        'max_co_hosts': maxCoHosts,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Information describing a participant in the live stream.
class Participant {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final UserRole role;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final DateTime joinedAt;

  const Participant({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.role = UserRole.viewer,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'viewer';
    final role = switch (roleStr.toLowerCase()) {
      'host' => UserRole.host,
      'co_host' || 'cohost' => UserRole.coHost,
      _ => UserRole.viewer,
    };

    return Participant(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: role,
      isAudioMuted: json['is_audio_muted'] as bool? ?? false,
      isVideoMuted: json['is_video_muted'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      };
}
