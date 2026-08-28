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
    final signingSecret = jwtSecret ?? apiSecret ?? 'default_secret';
    final jwt = JWT(
      {
        if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
        'roomId': roomId,
        'userId': userId,
        'role': role,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      },
      issuer: apiKey,
      subject: userId,
    );

    return jwt.sign(
      SecretKey(signingSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: expiresIn,
    );
  }
}
