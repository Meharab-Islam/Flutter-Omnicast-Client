import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Headless Architecture & Granular Atomic ValueNotifiers', () {
    late RoomState roomState;
    late SignalingClient signalingClient;
    late MediaStreamManager mediaStreamManager;
    late WebRTCManager webRTCManager;
    late RoomManager roomManager;
    late PKManager pkManager;
    late InteractionManager interactionManager;

    setUp(() {
      roomState = RoomState();
      signalingClient = SignalingClient();
      mediaStreamManager = MediaStreamManager();
      webRTCManager = WebRTCManager(mediaStreamManager: mediaStreamManager);

      roomManager = RoomManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

      pkManager = PKManager(
        signalingClient: signalingClient,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

      interactionManager = InteractionManager(
        signalingClient: signalingClient,
        roomState: roomState,
      );
    });

    tearDown(() async {
      roomManager.dispose();
      await pkManager.dispose();
      await interactionManager.dispose();
      await webRTCManager.dispose();
      await mediaStreamManager.dispose();
      await signalingClient.dispose();
      roomState.dispose();
    });

    test('viewerCountNotifier updates atomically without rebuilding entire state', () {
      expect(roomManager.viewerCountNotifier.value, 0);

      var notifiedCount = 0;
      roomManager.viewerCountNotifier.addListener(() => notifiedCount++);

      roomState.updateViewers(count: 42);
      expect(roomManager.viewerCountNotifier.value, 42);
      expect(notifiedCount, 1);
    });

    test('pkStateNotifier and timerNotifier update on battle state changes', () {
      expect(pkManager.pkStateNotifier.value.isPKActive, isFalse);

      roomState.updatePKBattle(PKBattleInfo(
        battleId: 'pk_100',
        hostRoomId: 'room_1',
        hostUserId: 'host_1',
        opponentRoomId: 'room_2',
        opponentUserId: 'opp_2',
        hostScore: 50,
        opponentScore: 20,
        remainingSeconds: 240,
        startedAt: DateTime.now(),
      ));

      expect(pkManager.pkStateNotifier.value.isPKActive, isTrue);
      expect(pkManager.isPKActiveNotifier.value, isTrue);
      expect(pkManager.timerNotifier.value, 240);
      expect(pkManager.pkStateNotifier.value.myScore, 50);
    });

    test('userBalanceNotifier and hostCoinBalanceNotifier update on balance and gift sync', () {
      expect(interactionManager.userBalanceNotifier.value, 0);
      expect(interactionManager.hostCoinBalanceNotifier.value, 0);

      roomState.setSession(
        roomId: 'room_1',
        userId: 'user_99',
        role: UserRole.viewer,
        hostId: 'host_1',
      );

      roomState.updateBalance(const BalanceUpdate(
        userId: 'user_99',
        newBalance: 1500,
        delta: 500,
        reason: 'purchase',
      ));

      expect(interactionManager.userBalanceNotifier.value, 1500);

      roomState.processGift(GiftEvent(
        giftId: 'rose',
        giftName: 'Rose',
        senderId: 'user_99',
        senderName: 'Fan',
        amount: 10,
        coinValue: 10,
        hostTotalCoins: 8000,
        timestamp: DateTime.now(),
      ));

      expect(interactionManager.hostCoinBalanceNotifier.value, 8000);
    });
  });

  group('Extreme Hardware Optimization & App Lifecycle', () {
    test('MediaController pauses camera when app enters background', () {
      final streamManager = MediaStreamManager();
      final signaling = SignalingClient();
      final webRTC = WebRTCManager(mediaStreamManager: streamManager);

      final controller = MediaController(
        mediaStreamManager: streamManager,
        signalingClient: signaling,
        webRTCManager: webRTC,
        autoPauseOnBackground: true,
      );

      // Camera is enabled initially
      expect(controller.isCameraEnabled, isTrue);

      // Simulate app going to background
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      // Simulates pausing
      expect(controller.isCameraEnabled, isFalse);

      // Simulate app resuming
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.isCameraEnabled, isTrue);

      controller.dispose();
      streamManager.dispose();
      signaling.dispose();
      webRTC.dispose();
    });
  });
}
