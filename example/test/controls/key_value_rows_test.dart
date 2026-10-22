import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/data/key_value.dart';
import 'package:grovs_example/ui/controls/key_value_rows.dart';
import 'package:grovs_example/ui/theme.dart';

void main() {
  testWidgets(
    'badge cycles type, add and remove rows, paste JSON replaces rows',
    (tester) async {
      var rows = <KeyValue>[const KeyValue(key: 'n', raw: '12')];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => KeyValueRows(
                rows: rows,
                label: 'Data',
                suggestedKeys: const ['promo'],
                onChanged: (v) => setState(() => rows = v),
              ),
            ),
          ),
        ),
      );
      expect(find.text('123'), findsOneWidget);
      await tester.tap(find.text('123'));
      await tester.pump();
      expect(rows.single.type, ValueType.boolean);

      await tester.tap(find.text('+ promo'));
      await tester.pump();
      expect(rows.map((r) => r.key), ['n', 'promo']);

      await tester.tap(find.text('×').last);
      await tester.pump();
      expect(rows.length, 1);

      await tester.tap(find.text('Paste JSON'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '{"level": 3}');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(rows.single.value(), 3);
    },
  );

  testWidgets('invalid JSON shows an error and keeps the rows', (tester) async {
    var rows = <KeyValue>[const KeyValue(key: 'n', raw: '12')];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: KeyValueRows(
            rows: rows,
            label: 'Data',
            onChanged: (v) => rows = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Paste JSON'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'nope');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Not valid JSON'), findsOneWidget);
    expect(rows.single.key, 'n');
  });
}
