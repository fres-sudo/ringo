import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_tostore/storage_tostore.dart';

import 'package:ringo/app/app.dart';

void main() {
  late ToStoreStorage storage;

  setUp(() async => storage = await ToStoreStorage.inMemory());

  testWidgets('renders the onboarding welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(RingoApp(storage: storage));

    expect(find.text('Sleepyal'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('Relax, unwind'), findsOneWidget);
  });

  testWidgets('continues from onboarding to the profile setup flow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RingoApp(storage: storage));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Setup'), findsOneWidget);
  });

  testWidgets('opens each primary destination from its named route', (
    WidgetTester tester,
  ) async {
    const destinations = [
      ('/dashboard', 'Dashboard coming soon'),
      ('/sleep', 'No sleep data yet'),
      ('/exercise', 'Exercise coming soon'),
      ('/food-tracking', 'Food tracking coming soon'),
      ('/profile', 'Profile coming soon'),
    ];

    for (final (route, placeholder) in destinations) {
      await tester.pumpWidget(
        KeyedSubtree(
          key: ValueKey(route),
          child: RingoApp(storage: storage, initialRoute: route),
        ),
      );

      expect(find.text(placeholder), findsOneWidget);
      for (final label in ['Home', 'Sleep', 'Exercise', 'Food', 'Profile']) {
        expect(
          find.byKey(ValueKey('bottom-navigation-${label.toLowerCase()}')),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('switches primary destinations from the bottom navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RingoApp(storage: storage, initialRoute: '/dashboard'),
    );

    await tester.tap(find.byKey(const ValueKey('bottom-navigation-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Profile coming soon'), findsOneWidget);
  });
}
