import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_example/main.dart';

void main() {
  testWidgets('OmniCastDemoApp renders LobbyScreen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OmniCastDemoApp());

    expect(find.text('OmniCast Live'), findsOneWidget);
    expect(find.text('WebRTC SFU Live Streaming & PK Engine'), findsOneWidget);
    expect(find.text('Host (Broadcast)'), findsOneWidget);
    expect(find.text('Viewer (Watch)'), findsOneWidget);
    expect(find.text('Start Broadcasting'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
