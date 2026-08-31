import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoParameters Presets & Constraints', () {
    test('mediaConstraints limits resolution and caps framerate at 30 (ideal 24)', () {
      const params = VideoParameters.presetSmooth480p;

      final constraints = params.toMediaConstraints(video: true, audio: true);
      expect(constraints['audio'], isA<Map<String, dynamic>>());
      expect(constraints['video']['mandatory']['minWidth'], '480');
      expect(constraints['video']['mandatory']['minHeight'], '640');
      expect(constraints['video']['mandatory']['maxWidth'], '720');
      expect(constraints['video']['mandatory']['maxHeight'], '1280');
      expect(constraints['video']['mandatory']['minFrameRate'], '15');
      expect(constraints['video']['mandatory']['maxFrameRate'], '30');
      expect(constraints['video']['frameRate']['ideal'], 24);
      expect(constraints['video']['facingMode'], 'user');
    });

    test('WebRTCManager default rtcConfiguration sets unrestricted UDP iceTransportPolicy', () {
      final streamManager = MediaStreamManager();
      final webRTC = WebRTCManager(mediaStreamManager: streamManager);
      expect(webRTC.rtcConfiguration['iceTransportPolicy'], 'all');
      expect(webRTC.rtcConfiguration['bundlePolicy'], 'max-bundle');
      expect(webRTC.rtcConfiguration['rtcpMuxPolicy'], 'require');
      streamManager.dispose();
      webRTC.dispose();
    });

    test('WebRTCManager preferCodec prioritizes H264 or VP8 in m=video line', () {
      const sampleSdp = 'v=0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96 97 98\r\na=rtpmap:96 VP8/90000\r\na=rtpmap:97 VP9/90000\r\na=rtpmap:98 H264/90000\r\n';
      final h264Sdp = WebRTCManager.preferCodec(sampleSdp, 'H264');
      expect(h264Sdp, contains('m=video 9 UDP/TLS/RTP/SAVPF 98 96 97'));

      final vp8Sdp = WebRTCManager.preferCodec(sampleSdp, 'VP8');
      expect(vp8Sdp, contains('m=video 9 UDP/TLS/RTP/SAVPF 96 97 98'));
    });

    test('WebRTCManager setInitialBitrate injects b=AS and x-google bitrates', () {
      const sampleSdp = 'v=0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\na=rtpmap:96 H264/90000\r\na=fmtp:96 level-asymmetry-allowed=1\r\n';
      final bitratedSdp = WebRTCManager.setInitialBitrate(sampleSdp, startKbps: 500, minKbps: 150, maxKbps: 800);
      expect(bitratedSdp, contains('b=AS:500'));
      expect(bitratedSdp, contains('b=TIAS:500000'));
      expect(bitratedSdp, contains('x-google-start-bitrate=500'));
      expect(bitratedSdp, contains('x-google-min-bitrate=150'));
      expect(bitratedSdp, contains('x-google-max-bitrate=800'));
    });

    test('WebRTCManager enableOpusDtx injects usedtx=1 into Opus fmtp line', () {
      const sampleSdp = 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\na=rtpmap:111 opus/48000/2\r\na=fmtp:111 minptime=10\r\n';
      final dtxSdp = WebRTCManager.enableOpusDtx(sampleSdp);
      expect(dtxSdp, contains('a=fmtp:111 minptime=10;usedtx=1;useinbandfec=1'));
    });

    test('presetHD720p constraints video and audio flags', () {
      const params = VideoParameters.presetHD720p;
      final constraints = params.toMediaConstraints(video: true, audio: true);
      expect(constraints['audio'], isA<Map<String, dynamic>>());
      expect(constraints['video']['mandatory']['minWidth'], '480');
      expect(constraints['video']['mandatory']['maxWidth'], '720');
      expect(constraints['video']['mandatory']['maxHeight'], '1280');
    });

    test('presetFHD1080p constraints when audio is false', () {
      const params = VideoParameters.presetFHD1080p;
      final constraints = params.toMediaConstraints(video: true, audio: false);
      expect(constraints['audio'], isFalse);
      expect(constraints['video']['mandatory']['minWidth'], '480');
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
