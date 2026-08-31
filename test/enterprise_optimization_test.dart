import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  group('Enterprise Constraints & Audio Processing Tests', () {
    test('VideoParameters toMediaConstraints produces Google V2 DSP audio filters', () {
      const params = VideoParameters.presetSmooth480p;
      final constraints = params.toMediaConstraints(video: true, audio: true);

      expect(constraints['audio'], isA<Map<String, dynamic>>());
      final audioMap = constraints['audio'] as Map<String, dynamic>;
      expect(audioMap['echoCancellation'], isTrue);
      expect(audioMap['noiseSuppression'], isTrue);
      expect(audioMap['autoGainControl'], isTrue);
      expect(audioMap['googEchoCancellation'], isTrue);
      expect(audioMap['googEchoCancellation2'], isTrue);
      expect(audioMap['googNoiseSuppression'], isTrue);
      expect(audioMap['googNoiseSuppression2'], isTrue);
      expect(audioMap['googAutoGainControl'], isTrue);
      expect(audioMap['googAutoGainControl2'], isTrue);
      expect(audioMap['googHighpassFilter'], isTrue);
      expect(audioMap['googTypingNoiseDetection'], isTrue);

      expect(constraints['video']['mandatory']['minWidth'], '480');
      expect(constraints['video']['mandatory']['minHeight'], '640');
      expect(constraints['video']['mandatory']['maxWidth'], '720');
      expect(constraints['video']['mandatory']['maxHeight'], '1280');
      expect(constraints['video']['mandatory']['minFrameRate'], '15');
      expect(constraints['video']['mandatory']['maxFrameRate'], '30');
      expect(constraints['video']['frameRate']['ideal'], 24);
      expect(constraints['video']['facingMode'], 'user');
    });

    test('WebRTCManager enables Opus DTX and FEC in SDP', () {
      const sampleSdp = '''v=0
o=- 123456 2 IN IP4 127.0.0.1
s=-
t=0 0
m=audio 9 UDP/TLS/RTP/SAVPF 111
a=rtpmap:111 opus/48000/2
a=fmtp:111 minptime=10
m=video 9 UDP/TLS/RTP/SAVPF 96
a=rtpmap:96 VP8/90000''';

      final processedSdp = WebRTCManager.enableOpusDtx(sampleSdp);

      expect(processedSdp, contains('usedtx=1'));
      expect(processedSdp, contains('useinbandfec=1'));
    });
  });

  group('WebRTCStatsMonitor & Network Quality Metrics', () {
    test('NetworkQualityStats formats json correctly and handles initial state', () {
      final initial = NetworkQualityStats.initial();
      expect(initial.packetLossPercent, 0.0);
      expect(initial.rating, NetworkQualityRating.unknown);

      final stats = NetworkQualityStats(
        packetLossPercent: 1.5,
        jitterMs: 12.0,
        rttMs: 45.0,
        bitrateKbps: 850.0,
        totalPacketsLost: 15,
        totalPacketsReceived: 985,
        totalPacketsSent: 1200,
        rating: NetworkQualityRating.excellent,
        timestamp: DateTime.now(),
      );

      final json = stats.toJson();
      expect(json['packet_loss_percent'], 1.5);
      expect(json['jitter_ms'], 12.0);
      expect(json['rtt_ms'], 45.0);
      expect(json['bitrate_kbps'], 850.0);
      expect(json['rating'], 'excellent');
    });

    test('DataChannelManager exposes direct send methods', () async {
      final streamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: streamManager);
      final roomState = RoomState();

      final dataManager = DataChannelManager(
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

      expect(dataManager.isChannelOpen, isFalse);

      // Safe invocation when channel is closed (no crash)
      dataManager.sendDirectMessage({'type': 'ping'});
      dataManager.sendDirectBinary(Uint8List.fromList([1, 2, 3]));
      dataManager.sendGift(GiftEvent(
        giftId: 'rose',
        giftName: 'Rose',
        senderId: 'user_1',
        senderName: 'Alice',
        amount: 1,
        coinValue: 10,
        hostTotalCoins: 10,
        timestamp: DateTime.now(),
      ));

      await dataManager.dispose();
      await webRTCManager.dispose();
      await streamManager.dispose();
      roomState.dispose();
    });
  });
}
