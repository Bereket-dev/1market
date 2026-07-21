// Basic smoke test for the Koolan Flutter Web app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koolan/app.dart';

void main() {
  testWidgets('Koolan app renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KoolanApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Koolan app tolerates missing Supabase configuration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KoolanApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Loading…'), findsWidgets);
  });
}
