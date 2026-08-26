import 'package:flutter_test/flutter_test.dart';

import 'package:ringo/app/app.dart';

void main() {
  testWidgets('renders the onboarding welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RingoApp());

    expect(find.text('Sleepyal'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('Relax, unwind'), findsOneWidget);
  });
}
