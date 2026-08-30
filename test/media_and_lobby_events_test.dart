import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  group('MediaController Host Toggles & Remote Viewer Reactivity', () {
    late SignalingClient signaling;
    late MediaStreamManager streamManager;
    late WebRTCManager webRTCManager;
    late RoomState roomState;
    late MediaController controller;

    setUp(() {
      signaling = SignalingClient();
      streamManager = MediaStreamManager();
      webRTCManager = WebRTCManager(mediaStreamManager: streamManager);
      roomState = RoomState();

      controller = MediaController(
        mediaStreamManager: streamManager,
        signalingClient: signaling,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );
    });

    tearDown(() async {
      controller.dispose();
      await webRTCManager.dispose();
      await streamManager.dispose();
      await signaling.dispose();
      roomState.dispose();
    });

    test('toggleMute and toggleCamera update local state notifiers', () {
      expect(controller.isMicrophoneMuted, isFalse);
      expect(controller.isCameraEnabled, isTrue);

      controller.toggleMute(true);
      expect(controller.isMicrophoneMuted, isTrue);

      controller.toggleCamera(true); // isOff = true -> Camera disabled
      expect(controller.isCameraEnabled, isFalse);

      controller.toggleCamera(false); // isOff = false -> Camera enabled
      expect(controller.isCameraEnabled, isTrue);
    });

    test('viewer reacts to incoming media_state_changed signaling event', () async {
      String? updatedType;
      bool? updatedMuted;

      controller.onHostMediaStateChanged = (type, isMuted) {
        updatedType = type;
        updatedMuted = isMuted;
      };

      expect(controller.isHostCameraOffNotifier.value, isFalse);
      expect(controller.isHostMicrophoneMutedNotifier.value, isFalse);

      // Simulate incoming video muted event from host
      await signaling.handleRawMessage(
        '{"event":"media_state_changed","room_id":"room_1","user_id":"host_1","payload":{"type":"video","muted":true}}',
      );

      expect(controller.isHostCameraOffNotifier.value, isTrue);
      expect(updatedType, 'video');
      expect(updatedMuted, isTrue);

      // Simulate incoming audio muted event from host
      await signaling.handleRawMessage(
        '{"event":"media_state_changed","room_id":"room_1","user_id":"host_1","payload":{"type":"audio","muted":true}}',
      );

      expect(controller.isHostMicrophoneMutedNotifier.value, isTrue);
      expect(updatedType, 'audio');
      expect(updatedMuted, isTrue);
    });
  });

  group('SignalingClient Real-Time Lobby Auto-Updates', () {
    test('dispatches room_created and room_closed events reactively', () async {
      final signaling = SignalingClient();

      RoomModel? newRoom;
      String? closedRoomId;

      signaling.onRoomCreated.listen((room) => newRoom = room);
      signaling.onRoomClosed.listen((id) => closedRoomId = id);

      // Simulate room_created event
      await signaling.handleRawMessage(
        '{"event":"room_created","room_id":"room_999","user_id":"host_99","payload":{"room_id":"room_999","room_name":"Gaming Room","host_id":"host_99","viewer_count":12}}',
      );

      await Future.delayed(const Duration(milliseconds: 20));
      expect(newRoom, isNotNull);
      expect(newRoom!.roomId, 'room_999');
      expect(newRoom!.roomName, 'Gaming Room');

      // Simulate room_closed event
      await signaling.handleRawMessage(
        '{"event":"room_closed","room_id":"room_999","user_id":"host_99","payload":{"room_id":"room_999"}}',
      );

      await Future.delayed(const Duration(milliseconds: 20));
      expect(closedRoomId, 'room_999');

      await signaling.dispose();
    });
  });
}
