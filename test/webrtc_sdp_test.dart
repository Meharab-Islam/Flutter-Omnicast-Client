import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/src/webrtc/webrtc_manager.dart';

void main() {
  test('Test extractSdp with complex payloads', () {
    const pionSdp = 'v=0\r\no=- 12345 2 IN IP4 0.0.0.0\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0 1\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\nc=IN IP4 0.0.0.0\r\na=mid:0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\nc=IN IP4 0.0.0.0\r\na=mid:1\r\n';

    // 1. Map payload with sdp string
    final payload1 = {
      'event': 'sdp_offer',
      'room_id': 'room1',
      'user_id': 'user1',
      'payload': {'type': 'offer', 'sdp': pionSdp},
      'sdp': pionSdp,
      'type': 'offer',
    };
    final extracted1 = WebRTCManager.extractSdp(payload1);
    expect(extracted1, isNotNull);
    expect(extracted1!.contains('v=0'), isTrue);
    expect(extracted1.contains('a=mid:1'), isTrue);

    // 2. Escaped JSON string
    final payload2 = '{"type":"offer","sdp":"$pionSdp"}';
    final extracted2 = WebRTCManager.extractSdp(payload2);
    expect(extracted2, isNotNull);
    expect(extracted2!.contains('v=0'), isTrue);

    // 3. Nested string with literal \\r\\n
    final literalEscaped = pionSdp.replaceAll('\r\n', r'\r\n');
    final extracted3 = WebRTCManager.extractSdp(literalEscaped);
    expect(extracted3, isNotNull);
    expect(extracted3!.contains('v=0'), isTrue);
  });
}
