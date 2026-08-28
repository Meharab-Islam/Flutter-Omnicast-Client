import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OmniCastVideoView Headless Widget', () {
    late MediaStreamManager mediaStreamManager;

    setUp(() {
      mediaStreamManager = MediaStreamManager();
    });

    tearDown(() async {
      await mediaStreamManager.dispose();
    });

    testWidgets('renders custom placeholder when video is not ready',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastVideoView(
              mediaStreamManager: mediaStreamManager,
              userId: 'peer_1',
              placeholder: const Text('Connecting Video...'),
            ),
          ),
        ),
      );

      expect(find.text('Connecting Video...'), findsOneWidget);
    });

    testWidgets('renders lightweight SizedBox.shrink when no placeholder is passed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OmniCastVideoView(
              mediaStreamManager: mediaStreamManager,
              userId: 'local',
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
