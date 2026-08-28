import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PKState Model', () {
    test('calculates score ratios and win status correctly', () {
      const state = PKState(
        isPKActive: true,
        myScore: 7000,
        opponentScore: 3000,
        remainingSeconds: 180,
      );

      expect(state.totalScore, 10000);
      expect(state.hostScoreRatio, 0.7);
      expect(state.opponentScoreRatio, closeTo(0.3, 0.001));
      expect(state.isWinning, isTrue);
      expect(state.isLosing, isFalse);
      expect(state.isTied, isFalse);
      expect(state.remainingTime, const Duration(seconds: 180));
    });

    test('clamps ratios when scores are extreme or zero', () {
      const zeroState = PKState(myScore: 0, opponentScore: 0);
      expect(zeroState.hostScoreRatio, 0.5);

      const dominantState = PKState(myScore: 10000, opponentScore: 0);
      expect(dominantState.hostScoreRatio, 0.95);
    });
  });

  group('PK & Gift UI Widgets', () {
    testWidgets('PKScoreProgressBar renders score counters and VS badge',
        (tester) async {
      const pkState = PKState(
        isPKActive: true,
        myScore: 500,
        opponentScore: 250,
        remainingSeconds: 120,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PKScoreProgressBar(pkState: pkState),
          ),
        ),
      );

      expect(find.text('500'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('02:00'), findsOneWidget);
    });

    testWidgets('OmniCastPKBattleView renders host and opponent video panes',
        (tester) async {
      final mediaManager = MediaStreamManager();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastPKBattleView(
              mediaStreamManager: mediaManager,
              hostUserId: 'host_101',
              opponentUserId: 'opponent_202',
              hostDisplayName: 'Alice (Host)',
              opponentDisplayName: 'Bob (Opponent)',
              pkState: const PKState(
                isPKActive: true,
                myScore: 100,
                opponentScore: 200,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Alice (Host)'), findsOneWidget);
      expect(find.text('Bob (Opponent)'), findsOneWidget);
      expect(find.byType(OmniCastVideoView), findsNWidgets(2));
      expect(find.byType(PKScoreProgressBar), findsOneWidget);

      await mediaManager.dispose();
    });

    testWidgets('GiftOverlayManager renders animated sliding gift banner',
        (tester) async {
      final giftController = StreamController<GiftEvent>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftOverlayManager(
              giftStream: giftController.stream,
              child: const Center(child: Text('Video Area')),
            ),
          ),
        ),
      );

      expect(find.text('Video Area'), findsOneWidget);
      expect(find.text('Sent Rocket'), findsNothing);

      // Fire a gift event
      giftController.add(GiftEvent(
        giftId: 'rocket',
        giftName: 'Rocket',
        senderId: 'fan_1',
        senderName: 'TopFan',
        amount: 2,
        coinValue: 50,
        hostTotalCoins: 1000,
        timestamp: DateTime.now(),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('TopFan'), findsOneWidget);
      expect(find.text('Sent Rocket'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);

      await giftController.close();
    });
  });

  group('RoomState Atomic PK Score Gift Synchronization', () {
    test('atomically updates PK battle host score on gift_processed event', () {
      final roomState = RoomState();
      roomState.setSession(
        roomId: 'room_1',
        userId: 'host_1',
        role: UserRole.host,
      );

      roomState.updatePKBattle(PKBattleInfo(
        battleId: 'pk_1',
        hostRoomId: 'room_1',
        hostUserId: 'host_1',
        opponentRoomId: 'room_2',
        opponentUserId: 'opponent_2',
        hostScore: 100,
        opponentScore: 100,
        startedAt: DateTime.now(),
      ));

      expect(roomState.pkState.myScore, 100);

      // Process gift to host
      roomState.processGift(GiftEvent(
        giftId: 'dragon',
        giftName: 'Golden Dragon',
        senderId: 'donor_1',
        senderName: 'Donor',
        targetUserId: 'host_1',
        amount: 3,
        coinValue: 100,
        hostTotalCoins: 5000,
        timestamp: DateTime.now(),
      ));

      // 100 + (3 * 100) = 400
      expect(roomState.pkState.myScore, 400);
      expect(roomState.pkState.opponentScore, 100);
      expect(roomState.pkState.isWinning, isTrue);

      roomState.reset();
    });
  });
}
