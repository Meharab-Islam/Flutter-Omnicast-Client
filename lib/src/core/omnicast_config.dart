import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Configuration credentials and connection parameters for initializing [OmniCastClient].
class OmniCastConfig {
  /// The project API Key issued from the OmniCast Dashboard.
  final String apiKey;

  /// The project API Secret used for local token signing or HMAC authentication.
  final String apiSecret;

  /// The base URL (WebSocket / HTTP) for the OmniCast SFU signaling cluster.
  /// Example: `wss://sfu.omnicast.live/ws`
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
    required this.apiKey,
    required this.apiSecret,
    required this.hostUrl,
    this.iceServers = const [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    this.heartbeatInterval = const Duration(seconds: 15),
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
  });

  /// Generates a signed authentication token for the given [userId] and [roomId].
  String generateAuthToken({required String userId, required String roomId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$apiKey:$userId:$roomId:$timestamp';
    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    final signature = hmac.convert(utf8.encode(payload)).toString();
    final authData = {
      'apiKey': apiKey,
      'userId': userId,
      'roomId': roomId,
      'timestamp': timestamp,
      'signature': signature,
    };
    return base64Url.encode(utf8.encode(jsonEncode(authData)));
  }
}
