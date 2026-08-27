import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import '../helpers/pump_component.dart';

void main() {
  testWidgets('highlights the initial item with a visible selection band', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpComponent(
        AppWheelPicker<String>(
          items: const ['186 cm', '187 cm', '188 cm'],
          initialItem: 1,
          itemLabel: (value) => value,
          semanticsLabel: 'Height picker',
          onSelectedItemChanged: (_) {},
        ),
        brightness: brightness,
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Height picker'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsOneWidget);

      final band = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxHeight == 52 &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).border != null,
        ),
      );
      final decoration = band.decoration! as BoxDecoration;
      expect(
        decoration.color,
        brightness == Brightness.light
            ? AppColors.light.secondary
            : AppColors.dark.secondary,
      );
      expect((decoration.border! as Border).top.width, greaterThan(1));
    }
  });

  testWidgets('reports the item that becomes centred', (tester) async {
    String? picked;
    await tester.pumpComponent(
      AppWheelPicker<String>(
        items: const ['186 cm', '187 cm', '188 cm'],
        itemLabel: (value) => value,
        onSelectedItemChanged: (value) => picked = value,
      ),
    );

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(picked, '187 cm');
  });
}
