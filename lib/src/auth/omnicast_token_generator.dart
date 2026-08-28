import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Standalone token generation utility using [dart_jsonwebtoken] for OmniCast SFU authentication.
abstract final class OmniCastTokenGenerator {
  /// Generates a cryptographically signed JWT authentication token for a live room session.
  ///
  /// Can be used on client development environments or backend services to issue tokens without
  /// exposing API secrets to the primary SDK initialization facade.
  static String generate({
    required String apiKey,
    required String apiSecret,
    required String roomId,
    required String userId,
    required String role,
    Map<String, dynamic>? metadata,
    Duration expiresIn = const Duration(hours: 24),
  }) {
    final jwt = JWT(
      {
        'apiKey': apiKey,
        'roomId': roomId,
        'userId': userId,
        'role': role,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      },
      issuer: apiKey,
      subject: userId,
    );

    return jwt.sign(
      SecretKey(apiSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: expiresIn,
    );
  }
}
