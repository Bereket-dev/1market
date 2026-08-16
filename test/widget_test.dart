// Basic smoke test for the Koolan Flutter Web app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koolan/app.dart';

void main() {
  testWidgets('Koolan app renders without crashing', (
    WidgetTester tester,
  ) async {
    // bootstrapPending paints branded boot UI without blocking on services.
    await tester.pumpWidget(const KoolanApp(bootstrapPending: true));
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Koolan app shows branded boot while pending', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KoolanApp(bootstrapPending: true));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Loading…'), findsWidgets);
  });
}
