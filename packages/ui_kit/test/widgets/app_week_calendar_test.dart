import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import '../helpers/pump_component.dart';

void main() {
  testWidgets('renders a weekly calendar and reports day selection', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      DateTime? selected;
      await tester.pumpComponent(
        SizedBox(
          width: 375,
          child: AppWeekCalendar<String>(
            selectedDay: DateTime(2026, 1, 14),
            focusedDay: DateTime(2026, 1, 14),
            firstDay: DateTime(2026, 1, 1),
            lastDay: DateTime(2026, 1, 31),
            eventLoader: (day) => day.day == 15 ? ['sleep'] : const [],
            onDaySelected: (day, _) => selected = day,
          ),
        ),
        brightness: brightness,
      );

      expect(find.byType(AppWeekCalendar<String>), findsOneWidget);
      expect(find.byTooltip('Previous week'), findsOneWidget);
      expect(find.byTooltip('Next week'), findsOneWidget);

      await tester.tap(find.text('15'));
      expect(selected?.year, 2026);
      expect(selected?.month, 1);
      expect(selected?.day, 15);
    }
  });
}
