import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/ui/controls/chips.dart';
import 'package:grovs_example/ui/theme.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('ChipInput adds on comma, skips duplicates and removes on tap', (
    tester,
  ) async {
    var values = <String>['a'];
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => ChipInput(
            values: values,
            onChanged: (v) => setState(() => values = v),
            max: 2,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'b, a,');
    await tester.pump();
    expect(values, ['a', 'b']);
    expect(find.text('2 of 2'), findsOneWidget);
    await tester.tap(find.text('a'));
    await tester.pump();
    expect(values, ['b']);
  });

  testWidgets('ChipPicker Other shows a field and selects typed text', (
    tester,
  ) async {
    var selected = 'USD';
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => ChipPicker(
            options: const ['USD', 'EUR'],
            selected: selected,
            otherPlaceholder: 'Code',
            onSelect: (v) => setState(() => selected = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Other…'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'JPY');
    await tester.pump();
    expect(selected, 'JPY');
    expect(find.text('JPY'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
  });
}
