// Basic smoke test for the Koolan Flutter Web app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koolan/app.dart';

void main() {
  testWidgets('Koolan app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const KoolanApp());
    // The bottom navigation bar should be present on the home screen.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
