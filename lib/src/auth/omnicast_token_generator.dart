import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Standalone token generation utility using [dart_jsonwebtoken] for OmniCast SFU authentication.
abstract final class OmniCastTokenGenerator {
  /// Generates a cryptographically signed JWT authentication token for a live room session.
  ///
  /// Uses [jwtSecret] or [apiSecret] to sign the token with HMAC-SHA256.
  static String generate({
    String? apiKey,
    String? apiSecret,
    String? jwtSecret,
    required String roomId,
    required String userId,
    required String role,
    Map<String, dynamic>? metadata,
    Duration expiresIn = const Duration(hours: 24),
  }) {
    final signingSecret = jwtSecret ?? apiSecret ?? 'live_media_server_jwt_secret_key_2026';
    final canPublish = role == 'host' || role == 'cohost' || role == 'co_host' || role == 'publisher';
    final dName = metadata?['displayName'] ?? metadata?['display_name'] ?? metadata?['user_name'] ?? metadata?['name'];
    final aUrl = metadata?['avatarUrl'] ?? metadata?['avatar_url'] ?? metadata?['avatar'];

    final jwt = JWT(
      {
        if (apiKey != null && apiKey.isNotEmpty) ...{
          'api_key': apiKey,
          'apiKey': apiKey,
        },
        'user_id': userId,
        'userId': userId,
        'room_id': roomId,
        'roomId': roomId,
        'role': role,
        'can_publish': canPublish,
        'can_subscribe': true,
        if (dName != null) ...{
          'display_name': dName.toString(),
          'user_name': dName.toString(),
        },
        if (aUrl != null) ...{
          'avatar_url': aUrl.toString(),
        },
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      },
      issuer: apiKey ?? 'omnicast_engine',
      subject: userId,
    );

    return jwt.sign(
      SecretKey(signingSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: expiresIn,
    );
  }
}
