import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Standalone zero-dependency token generation utility for OmniCast SFU authentication.
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
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = now + expiresIn.inSeconds;

    final payload = {
      if (apiKey != null && apiKey.isNotEmpty) ...{
        'api_key': apiKey,
        'apiKey': apiKey,
      },
      'user_id': userId,
      'userId': userId,
      'room_id': roomId,
      'roomId': roomId,
      'role': role,
      'iat': now,
      'exp': exp,
      'sub': userId,
      if (apiKey != null && apiKey.isNotEmpty) 'iss': apiKey,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };

    String base64UrlEncode(String input) {
      return base64Url.encode(utf8.encode(input)).replaceAll('=', '');
    }

    final encodedHeader = base64UrlEncode(jsonEncode(header));
    final encodedPayload = base64UrlEncode(jsonEncode(payload));
    final signingInput = '$encodedHeader.$encodedPayload';

    final hmac = Hmac(sha256, utf8.encode(signingSecret));
    final signature = base64Url.encode(hmac.convert(utf8.encode(signingInput)).bytes).replaceAll('=', '');

    return '$signingInput.$signature';
  }
}
