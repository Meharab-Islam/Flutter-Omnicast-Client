import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoomMode & PkScore State Management', () {
    late RoomState roomState;

    setUp(() {
      roomState = RoomState();
    });

    tearDown(() {
      roomState.dispose();
    });

    test('initial state defaults to RoomMode.solo and PkScore(0, 0)', () {
      expect(roomState.roomMode, RoomMode.solo);
      expect(roomState.roomModeNotifier.value, RoomMode.solo);
      expect(roomState.pkScoreNotifier.value.hostScore, 0);
      expect(roomState.pkScoreNotifier.value.opponentScore, 0);
    });

    test('updating PK battle transitions RoomMode to pk and sets PkScore', () {
      final battle = PKBattleInfo(
        battleId: 'pk_123',
        hostRoomId: 'room_a',
        hostUserId: 'host_a',
        opponentRoomId: 'room_b',
        opponentUserId: 'host_b',
        status: PKStatus.inProgress,
        hostScore: 100,
        opponentScore: 250,
        durationSeconds: 300,
        remainingSeconds: 280,
        startedAt: DateTime.now(),
      );

      roomState.updatePKBattle(battle);

      expect(roomState.roomMode, RoomMode.pk);
      expect(roomState.roomModeNotifier.value, RoomMode.pk);
      expect(roomState.pkScoreNotifier.value.hostScore, 100);
      expect(roomState.pkScoreNotifier.value.opponentScore, 250);
      expect(roomState.pkScoreNotifier.value.hostRatio, closeTo(100 / 350, 0.01));
    });

    test('updating PK scores updates pkScoreNotifier atomically', () {
      roomState.updatePKBattle(PKBattleInfo(
        battleId: 'pk_123',
        hostRoomId: 'room_a',
        hostUserId: 'host_a',
        opponentRoomId: 'room_b',
        opponentUserId: 'host_b',
        status: PKStatus.inProgress,
        hostScore: 0,
        opponentScore: 0,
        durationSeconds: 300,
        remainingSeconds: 300,
        startedAt: DateTime.now(),
      ));

      roomState.updatePKScore(const PKScoreUpdate(
        battleId: 'pk_123',
        hostScore: 600,
        opponentScore: 400,
      ));

      expect(roomState.pkScoreNotifier.value.hostScore, 600);
      expect(roomState.pkScoreNotifier.value.opponentScore, 400);
      expect(roomState.pkScoreNotifier.value.hostRatio, 0.6);
      expect(roomState.pkScoreNotifier.value.opponentRatio, 0.4);
    });

    test('ending PK battle resets RoomMode back to solo and clears scores', () {
      roomState.updatePKBattle(PKBattleInfo(
        battleId: 'pk_123',
        hostRoomId: 'room_a',
        hostUserId: 'host_a',
        opponentRoomId: 'room_b',
        opponentUserId: 'host_b',
        status: PKStatus.inProgress,
        hostScore: 50,
        opponentScore: 50,
        durationSeconds: 300,
        remainingSeconds: 300,
        startedAt: DateTime.now(),
      ));

      roomState.endPKBattle();

      expect(roomState.roomMode, RoomMode.solo);
      expect(roomState.roomModeNotifier.value, RoomMode.solo);
      expect(roomState.pkScoreNotifier.value.hostScore, 0);
      expect(roomState.pkScoreNotifier.value.opponentScore, 0);
    });
  });

  group('OmniCastVideoCanvas Widget', () {
    testWidgets('renders solo layout by default and switches to PK split-screen on state change',
        (tester) async {
      final roomState = RoomState();
      final signalingClient = SignalingClient();
      final streamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: streamManager);

      final client = OmniCastClient.custom(
        config: const OmniCastConfig(
          hostUrl: 'ws://localhost',
          heartbeatInterval: Duration.zero,
        ),
        mediaConfig: const GlobalMediaConfig(
          autoPauseOnBackground: false,
        ),
        roomState: roomState,
        signalingClient: signalingClient,
        mediaStreamManager: streamManager,
        webRTCManager: webRTCManager,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 700,
              child: OmniCastVideoCanvas(
                client: client,
                hostName: 'Alice Host',
                opponentName: 'Bob Host',
              ),
            ),
          ),
        ),
      );

      // Solo mode: Host is displayed, no VS badge
      expect(find.text('Alice Host'), findsOneWidget);
      expect(find.text('VS'), findsNothing);

      // Trigger PK Battle
      client.state.updatePKBattle(PKBattleInfo(
        battleId: 'pk_456',
        hostRoomId: 'room_a',
        hostUserId: 'host_a',
        opponentRoomId: 'room_b',
        opponentUserId: 'host_b',
        status: PKStatus.inProgress,
        hostScore: 500,
        opponentScore: 300,
        durationSeconds: 300,
        remainingSeconds: 300,
        startedAt: DateTime.now(),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // PK Split-Screen mode: Both hosts and score header (VS badge) are displayed
      expect(find.text('Alice Host'), findsAtLeast(1));
      expect(find.text('VS'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await client.dispose();
    });
  });

  group('OmniCastGiftingBottomSheet & Targeted Cross-Room Gifting', () {
    testWidgets('renders targeted host selector when in PK mode and single button when solo',
        (tester) async {
      final roomState = RoomState();
      final signalingClient = SignalingClient();
      final streamManager = MediaStreamManager();
      final webRTCManager = WebRTCManager(mediaStreamManager: streamManager);

      final client = OmniCastClient.custom(
        config: const OmniCastConfig(
          hostUrl: 'ws://localhost',
          heartbeatInterval: Duration.zero,
        ),
        mediaConfig: const GlobalMediaConfig(autoPauseOnBackground: false),
        roomState: roomState,
        signalingClient: signalingClient,
        mediaStreamManager: streamManager,
        webRTCManager: webRTCManager,
      );

      // 1. Solo Mode: No targeted toggle
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastGiftingBottomSheet(client: client),
          ),
        ),
      );

      expect(find.text('Send Virtual Gift'), findsOneWidget);
      expect(find.text('Support Host A (Blue)'), findsNothing);

      // 2. PK Battle Mode: Targeted Toggle is active
      client.state.updatePKBattle(PKBattleInfo(
        battleId: 'pk_789',
        hostRoomId: 'room_a',
        hostUserId: 'host_a',
        opponentRoomId: 'room_b',
        opponentUserId: 'host_b',
        opponentDisplayName: 'Rival Bob',
        status: PKStatus.inProgress,
        hostScore: 0,
        opponentScore: 0,
        durationSeconds: 300,
        remainingSeconds: 300,
        startedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastGiftingBottomSheet(client: client),
          ),
        ),
      );

      expect(find.text('Support Host A (Blue)'), findsOneWidget);
      expect(find.text('Support Rival Bob'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await client.dispose();
      await tester.pump();
    });
  });
}
