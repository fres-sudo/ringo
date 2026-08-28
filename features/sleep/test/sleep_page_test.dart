import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep/sleep.dart';

void main() {
  testWidgets('explains that a ring sync is needed before data is shown', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SleepPage()));

    expect(find.text('No sleep data yet'), findsOneWidget);
    expect(find.textContaining('Connect a supported ring'), findsOneWidget);
  });
}
