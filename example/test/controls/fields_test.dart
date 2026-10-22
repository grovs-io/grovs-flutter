import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/ui/controls/fields.dart';
import 'package:grovs_example/ui/theme.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('LinkField shows the extracted path', (tester) async {
    await tester.pumpWidget(
      host(
        LinkField(
          value: 'https://x.sqd.link/abc',
          onChanged: (_) {},
          showPath: true,
        ),
      ),
    );
    expect(find.text('Path: abc'), findsOneWidget);
  });

  testWidgets('MoneyField shows cents and errors', (tester) async {
    await tester.pumpWidget(
      host(MoneyField(amount: '4.99', onChanged: (_) {}, currency: 'USD')),
    );
    expect(find.text('Sent as 499 cents'), findsOneWidget);
    await tester.pumpWidget(
      host(MoneyField(amount: '4.999', onChanged: (_) {}, currency: 'USD')),
    );
    expect(find.text('Enter an amount like 4.99'), findsOneWidget);
  });

  testWidgets('SuggestField clear button empties the value', (tester) async {
    var value = 'abc';
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SuggestField(
            value: value,
            suggestions: const ['x'],
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('✕'));
    await tester.pump();
    expect(value, '');
  });

  testWidgets('AppTextField follows outside value changes', (tester) async {
    var value = 'one';
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return AppTextField(value: value, onChanged: (v) => value = v);
          },
        ),
      ),
    );
    update(() => value = 'two');
    await tester.pump();
    expect(find.text('two'), findsOneWidget);
  });
}
