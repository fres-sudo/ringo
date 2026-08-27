import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding/onboarding.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  Widget subject() =>
      MaterialApp(theme: AppTheme.light, home: const OnboardingFlowPage());

  testWidgets('starts with the profile screen and opens a profile picker', (
    tester,
  ) async {
    await tester.pumpWidget(subject());

    expect(find.text('Profile Setup'), findsOneWidget);
    expect(find.text('Your data is safe and encrypted'), findsOneWidget);

    await tester.tap(find.text('Birth year'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Select'), findsNWidgets(3));
  });

  testWidgets('supports selecting a sleep preference with semantic feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SleepQuestionPage(
          question: 'How long do you usually take to fall asleep?',
          options: const ['Several minutes', 'Hard to fall asleep'],
          selected: 'Hard to fall asleep',
          onChanged: (_) {},
          onBack: () {},
          onSkip: () {},
          onNext: () {},
        ),
      ),
    );

    expect(
      tester
          .getSemantics(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label == 'Hard to fall asleep',
            ),
          )
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('uses real ring pairing as the final onboarding step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final manager = RingConnectionManager(adapter: MockRingBleAdapter());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OnboardingFlowPage(
          ringConnectionManager: manager,
          debugMockConnectionManager: manager,
        ),
      ),
    );

    for (final label in ['Birth year', 'Weight', 'Height']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Sex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Connect your ring'), findsOneWidget);
    expect(find.text('Find my ring'), findsOneWidget);
    expect(find.text('Smartwatch'), findsNothing);
  });
}
