/// Configuration connection parameters for initializing [OmniCastClient] with token-based auth.
class OmniCastConfig {
  /// The base URL (WebSocket / HTTP) for the OmniCast SFU signaling cluster.
  /// Example: `wss://omnilive.lolipoplive.top/ws`
  final String hostUrl;

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
    this.iceServers = const [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    this.heartbeatInterval = const Duration(seconds: 15),
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
  });
}
