import 'package:flutter_test/flutter_test.dart';

import 'package:ringo/app/app.dart';

void main() {
  testWidgets('renders the Ringo shell', (WidgetTester tester) async {
    await tester.pumpWidget(const RingoApp());

    expect(find.text('Ringo'), findsOneWidget);
  });
}
