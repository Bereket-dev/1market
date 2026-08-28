// Basic smoke test for the 1market Flutter Web app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onemarket/app.dart';

void main() {
  testWidgets('1market app renders without crashing', (
    WidgetTester tester,
  ) async {
    // bootstrapPending paints branded boot UI without blocking on services.
    await tester.pumpWidget(const OnemarketApp(bootstrapPending: true));
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('1market app shows branded boot while pending', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OnemarketApp(bootstrapPending: true));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Loading…'), findsWidgets);
  });
}
