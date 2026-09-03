import '../auth/omnicast_token_generator.dart';

/// Configuration parameters for initializing [OmniCastClient] with server credentials and token-based auth.
class OmniCastConfig {
  /// The base WebSocket URL for the OmniCast SFU signaling cluster.
  /// Example: `wss://testlive.lolipoplive.top/ws`
  final String hostUrl;

  /// The base HTTP REST API URL for the OmniCast backend.
  /// Example: `https://testlive.lolipoplive.top/api`
  final String? apiUrl;

  /// Public API Key identifying the project/application.
  final String? apiKey;

  /// Private API Secret for backend authentication.
  final String? apiSecret;

  /// Secret key specifically used for signing and verifying JWT room tokens.
  /// If omitted, automatically defaults to [apiSecret].
  final String? jwtSecret;

  /// Optional custom ICE (STUN/TURN) server configurations.
  final List<Map<String, dynamic>> iceServers;

  /// WebSocket keep-alive heartbeat interval. Defaults to 15 seconds.
  final Duration heartbeatInterval;

  /// Auto-reconnection backoff duration. Defaults to 3 seconds.
  final Duration reconnectDelay;

  /// Maximum automatic reconnection attempts before entering error state.
  final int maxReconnectAttempts;

  /// Whether debug console logging is enabled. Defaults to false.
  final bool enableLogging;

  const OmniCastConfig({
    required this.hostUrl,
    this.apiUrl,
    this.apiKey,
    this.apiSecret,
    String? jwtSecret,
    this.iceServers = const [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    this.heartbeatInterval = const Duration(seconds: 15),
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
    this.enableLogging = false,
  })  : jwtSecret = jwtSecret ?? apiSecret;

  /// Factory constructor that automatically normalizes any server domain or URL.
  factory OmniCastConfig.fromServer({
    String? serverUrl,
    String? hostUrl,
    String? apiUrl,
    String? apiKey,
    String? apiSecret,
    String? jwtSecret,
    List<Map<String, dynamic>>? iceServers,
    Duration heartbeatInterval = const Duration(seconds: 15),
    Duration reconnectDelay = const Duration(seconds: 3),
    int maxReconnectAttempts = 5,
    bool enableLogging = false,
    bool? isSecure,
    String wsPath = '/ws',
    String apiPath = '/api',
  }) {
    final effectiveHostUrl = hostUrl != null
        ? (hostUrl.startsWith('ws')
            ? hostUrl
            : deriveWebSocketUrl(hostUrl, wsPath: wsPath, useSsl: isSecure))
        : deriveWebSocketUrl(serverUrl ?? '127.0.0.1:8080',
            wsPath: wsPath, useSsl: isSecure);

    final effectiveApiUrl = apiUrl != null
        ? (apiUrl.startsWith('http')
            ? apiUrl
            : deriveApiUrl(apiUrl, apiPath: apiPath, useSsl: isSecure))
        : deriveApiUrl(serverUrl ?? hostUrl ?? '127.0.0.1:8080',
            apiPath: apiPath, useSsl: isSecure);

    return OmniCastConfig(
      hostUrl: effectiveHostUrl,
      apiUrl: effectiveApiUrl,
      apiKey: apiKey,
      apiSecret: apiSecret,
      jwtSecret: jwtSecret ?? apiSecret,
      iceServers: iceServers ??
          const [
            {'urls': 'stun:stun.l.google.com:19302'},
            {'urls': 'stun:stun1.l.google.com:19302'},
          ],
      heartbeatInterval: heartbeatInterval,
      reconnectDelay: reconnectDelay,
      maxReconnectAttempts: maxReconnectAttempts,
      enableLogging: enableLogging,
    );
  }

  /// Derives a clean, normalized WebSocket URL from any raw domain, host, or URL string.
  /// e.g. `testlive.lolipoplive.top` -> `wss://testlive.lolipoplive.top/ws`
  static String deriveWebSocketUrl(
    String input, {
    String wsPath = '/ws',
    bool? useSsl,
  }) {
    var raw = input.trim();
    if (raw.isEmpty) return 'ws://127.0.0.1:8080/ws';

    // If already a full ws/wss URL with path
    if (raw.startsWith('ws://') || raw.startsWith('wss://')) {
      if (!raw.endsWith('/ws') && !raw.contains('/ws?') && raw.endsWith('/')) {
        return '${raw.substring(0, raw.length - 1)}$wsPath';
      }
      return raw.contains('/ws') ? raw : '$raw$wsPath';
    }

    bool isSecure = useSsl ?? true;
    if (raw.startsWith('http://')) {
      isSecure = false;
      raw = raw.replaceFirst('http://', '');
    } else if (raw.startsWith('https://')) {
      isSecure = true;
      raw = raw.replaceFirst('https://', '');
    }

    if (raw.contains('localhost') || raw.contains('127.0.0.1')) {
      if (useSsl == null) isSecure = false;
    }

    if (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }

    if (!raw.contains('/')) {
      raw = '$raw$wsPath';
    }

    final scheme = isSecure ? 'wss://' : 'ws://';
    return '$scheme$raw';
  }

  /// Derives a clean, normalized REST API URL from any raw domain, host, or URL string.
  /// e.g. `testlive.lolipoplive.top` -> `https://testlive.lolipoplive.top/api`
  static String deriveApiUrl(
    String input, {
    String apiPath = '/api',
    bool? useSsl,
  }) {
    var raw = input.trim();
    if (raw.isEmpty) return 'http://127.0.0.1:8080/api';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (!raw.endsWith('/api') && !raw.contains('/api/') && raw.endsWith('/')) {
        return '${raw.substring(0, raw.length - 1)}$apiPath';
      }
      return raw.contains('/api') ? raw : '$raw$apiPath';
    }

    bool isSecure = useSsl ?? true;
    if (raw.startsWith('ws://')) {
      isSecure = false;
      raw = raw.replaceFirst('ws://', '');
    } else if (raw.startsWith('wss://')) {
      isSecure = true;
      raw = raw.replaceFirst('wss://', '');
    }

    if (raw.contains('localhost') || raw.contains('127.0.0.1')) {
      if (useSsl == null) isSecure = false;
    }

    if (raw.endsWith('/ws')) {
      raw = raw.substring(0, raw.length - 3);
    }
    if (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }

    if (!raw.contains('/')) {
      raw = '$raw$apiPath';
    }

    final scheme = isSecure ? 'https://' : 'http://';
    return '$scheme$raw';
  }

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
      jwtSecret: jwtSecret ?? apiSecret,
      roomId: roomId,
      userId: userId,
      role: role,
      metadata: metadata,
      expiresIn: expiresIn,
    );
  }
}
