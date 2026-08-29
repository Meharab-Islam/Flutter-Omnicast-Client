import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoParameters Presets & Constraints', () {
    test('presetSmooth480p constraints match 640x480 @ 24fps with ideal constraints', () {
      const params = VideoParameters.presetSmooth480p;
      expect(params.width, 640);
      expect(params.height, 480);
      expect(params.frameRate, 24);
      expect(params.maxBitrate, 800000);

      final constraints = params.toMediaConstraints(video: true, audio: true);
      expect(constraints['audio'], isTrue);
      expect(constraints['video']['width']['ideal'], 640);
      expect(constraints['video']['height']['ideal'], 480);
      expect(constraints['video']['frameRate']['ideal'], 24);
    });

    test('WebRTCManager preferCodec prioritizes VP8 or VP9 in m=video line', () {
      const sampleSdp = 'v=0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96 97 98\r\na=rtpmap:96 H264/90000\r\na=rtpmap:97 VP9/90000\r\na=rtpmap:98 VP8/90000\r\n';
      final vp8Sdp = WebRTCManager.preferCodec(sampleSdp, 'VP8');
      expect(vp8Sdp, contains('m=video 9 UDP/TLS/RTP/SAVPF 98 96 97'));

      final vp9Sdp = WebRTCManager.preferCodec(sampleSdp, 'VP9');
      expect(vp9Sdp, contains('m=video 9 UDP/TLS/RTP/SAVPF 97 96 98'));
    });

    test('WebRTCManager enableOpusDtx injects usedtx=1 into Opus fmtp line', () {
      const sampleSdp = 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\na=rtpmap:111 opus/48000/2\r\na=fmtp:111 minptime=10\r\n';
      final dtxSdp = WebRTCManager.enableOpusDtx(sampleSdp);
      expect(dtxSdp, contains('a=fmtp:111 minptime=10;usedtx=1;useinbandfec=1'));
    });

    test('presetHD720p constraints match 1280x720 @ 30fps', () {
      const params = VideoParameters.presetHD720p;
      expect(params.width, 1280);
      expect(params.height, 720);
      expect(params.frameRate, 30);
      expect(params.maxBitrate, 2500000);

      final constraints = params.toMediaConstraints(video: true, audio: true);
      expect(constraints['audio'], isTrue);
      expect(constraints['video']['mandatory']['minWidth'], '1280');
      expect(constraints['video']['mandatory']['minHeight'], '720');
      expect(constraints['video']['mandatory']['minFrameRate'], '30');
    });

    test('presetFHD1080p constraints match 1920x1080 @ 30fps', () {
      const params = VideoParameters.presetFHD1080p;
      expect(params.width, 1920);
      expect(params.height, 1080);
      expect(params.maxBitrate, 4500000);

      final constraints = params.toMediaConstraints(video: true, audio: false);
      expect(constraints['audio'], isFalse);
      expect(constraints['video']['mandatory']['minWidth'], '1920');
      expect(constraints['video']['mandatory']['minHeight'], '1080');
    });

    test('custom video parameters generation', () {
      final custom = VideoParameters.custom(
        width: 1024,
        height: 768,
        fps: 60,
        maxBitrate: 3000000,
      );

      expect(custom.width, 1024);
      expect(custom.height, 768);
      expect(custom.frameRate, 60);
      expect(custom.maxBitrate, 3000000);

      final constraints = custom.toMediaConstraints();
      expect(constraints['video']['mandatory']['minWidth'], '1024');
      expect(constraints['video']['mandatory']['minHeight'], '768');
      expect(constraints['video']['mandatory']['minFrameRate'], '60');
    });
  });

  group('MediaController Simulcast & Dynacast Toggles', () {
    test('manages simulcast layer selection and dynacast toggles', () {
      final signaling = SignalingClient();
      final streamManager = MediaStreamManager();
      final webRTC = WebRTCManager(mediaStreamManager: streamManager);

      final roomState = RoomState();
      final controller = MediaController(
        mediaStreamManager: streamManager,
        signalingClient: signaling,
        webRTCManager: webRTC,
        roomState: roomState,
      );

      expect(controller.currentSimulcastLayer, 'f');
      expect(controller.adaptiveStreamingEnabled, isTrue);
      expect(controller.dynacastEnabled, isTrue);

      controller.setSimulcastLayer('h');
      expect(controller.currentSimulcastLayer, 'h');

      controller.enableDynacast(false);
      expect(controller.dynacastEnabled, isFalse);

      controller.enableAdaptiveStreaming(false);
      expect(controller.adaptiveStreamingEnabled, isFalse);

      controller.dispose();
      streamManager.dispose();
      signaling.dispose();
      webRTC.dispose();
    });
  });
}
