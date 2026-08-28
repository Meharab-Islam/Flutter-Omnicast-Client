import '../auth/omnicast_token_generator.dart';

/// Configuration parameters for initializing [OmniCastClient] with server credentials and token-based auth.
class OmniCastConfig {
  /// The base WebSocket URL for the OmniCast SFU signaling cluster.
  /// Example: `wss://omnilive.lolipoplive.top/ws`
  final String hostUrl;

  /// Optional base HTTP REST API URL for the OmniCast backend.
  /// Example: `https://omnilive.lolipoplive.top/api`
  final String? apiUrl;

  /// Public API Key identifying the project/application.
  final String? apiKey;

  /// Private API Secret for backend authentication.
  final String? apiSecret;

  /// Secret key specifically used for signing and verifying JWT room tokens.
  final String? jwtSecret;

  /// Optional custom ICE (STUN/TURN) server configurations.
  final List<Map<String, dynamic>> iceServers;

  /// WebSocket keep-alive heartbeat interval. Defaults to 15 seconds.
  final Duration heartbeatInterval;

  /// Auto-reconnection backoff duration. Defaults to 3 seconds.
  final Duration reconnectDelay;

  /// Maximum automatic reconnection attempts before entering error state.
  final int maxReconnectAttempts;

  const OmniCastConfig({
    required this.hostUrl,
    this.apiUrl,
    this.apiKey,
    this.apiSecret,
    this.jwtSecret,
    this.iceServers = const [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    this.heartbeatInterval = const Duration(seconds: 15),
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
  });

  /// Automatically generates a signed JWT token using the configured credentials.
  String generateToken({
    required String roomId,
    required String userId,
    required String role,
    Map<String, dynamic>? metadata,
    Duration expiresIn = const Duration(hours: 24),
  }) {
    return OmniCastTokenGenerator.generate(
      apiKey: apiKey,
      apiSecret: apiSecret,
      jwtSecret: jwtSecret,
      roomId: roomId,
      userId: userId,
      role: role,
      metadata: metadata,
      expiresIn: expiresIn,
    );
  }
}
