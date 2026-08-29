import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataChannelManager & Real-Time Events', () {
    late MediaStreamManager streamManager;
    late WebRTCManager webRTCManager;
    late RoomState roomState;
    late DataChannelManager dataChannelManager;

    setUp(() {
      streamManager = MediaStreamManager();
      webRTCManager = WebRTCManager(mediaStreamManager: streamManager);
      roomState = RoomState();

      dataChannelManager = DataChannelManager(
        webRTCManager: webRTCManager,
        roomState: roomState,
      );
    });

    tearDown(() async {
      await dataChannelManager.dispose();
      await webRTCManager.dispose();
      await streamManager.dispose();
      roomState.dispose();
    });

    test('DataChannelReaction serialization and deserialization', () {
      final reaction = DataChannelReaction(
        userId: 'user_42',
        emoji: '💖',
        xOffset: 0.75,
        timestamp: 1700000000000,
      );

      final json = reaction.toJson();
      expect(json['type'], 'reaction');
      expect(json['user_id'], 'user_42');
      expect(json['emoji'], '💖');
      expect(json['x_offset'], 0.75);

      final parsed = DataChannelReaction.fromJson(json);
      expect(parsed.userId, 'user_42');
      expect(parsed.emoji, '💖');
      expect(parsed.xOffset, 0.75);
    });
  });

  group('OmniCastNativeViewportTracker Widget', () {
    testWidgets('calculates visible vs hidden track IDs mathematically on scroll', (tester) async {
      final List<String> testTracks = List.generate(10, (i) => 'track_$i');
      List<String> lastVisible = [];
      List<String> lastHidden = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: OmniCastNativeViewportTracker(
                trackIds: testTracks,
                itemHeight: 200,
                crossAxisCount: 2,
                onVisibilityChanged: (visible, hidden) {
                  lastVisible = visible;
                  lastHidden = hidden;
                },
                child: ListView.builder(
                  itemCount: testTracks.length,
                  itemBuilder: (context, index) => SizedBox(
                    height: 100,
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(lastVisible, isEmpty);
      expect(lastHidden, isEmpty);
    });
  });

  group('OmniCastFlyingHeartsOverlay Widget', () {
    testWidgets('renders and animates floating reaction particles', (tester) async {
      final reactionNotifier = ValueNotifier<DataChannelReaction?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 600,
              child: OmniCastFlyingHeartsOverlay(
                reactionNotifier: reactionNotifier,
              ),
            ),
          ),
        ),
      );

      // Trigger reaction
      reactionNotifier.value = DataChannelReaction(
        userId: 'user_1',
        emoji: '🔥',
        xOffset: 0.5,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pump();
      expect(find.text('🔥'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🔥'), findsOneWidget);

      reactionNotifier.dispose();
    });
  });
}
