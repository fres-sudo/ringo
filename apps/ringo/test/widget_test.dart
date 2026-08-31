import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storage_tostore/storage_tostore.dart';

import 'package:ringo/app/app.dart';
import 'package:ringo/app/dependency_injector.dart';

void main() {
  late ToStoreStorage storage;

  setUp(() async => storage = await ToStoreStorage.inMemory());

  Widget subject({String? initialRoute}) => DependencyInjector(
    services: [Provider<Storage>.value(value: storage)],
    child: RingoApp(initialRoute: initialRoute),
  );

  testWidgets('renders the onboarding welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Setup'), findsOneWidget);
  });

  testWidgets('opens each primary destination from its named route', (
    WidgetTester tester,
  ) async {
    const destinations = [
      ('/dashboard', 'Dashboard coming soon'),
      ('/sleep', 'Sleep'),
      ('/exercise', 'Exercise coming soon'),
      ('/food-tracking', 'Food tracking coming soon'),
      ('/profile', 'Profile coming soon'),
    ];

    for (final (route, placeholder) in destinations) {
      await tester.pumpWidget(
        KeyedSubtree(
          key: ValueKey(route),
          child: subject(initialRoute: route),
        ),
      );
      await tester.pumpAndSettle();

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
    await tester.pumpWidget(subject(initialRoute: '/dashboard'));

    await tester.tap(find.byKey(const ValueKey('bottom-navigation-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Profile coming soon'), findsOneWidget);
  });
}
