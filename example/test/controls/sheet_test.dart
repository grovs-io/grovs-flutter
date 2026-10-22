import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/ui/controls/sheet.dart';
import 'package:grovs_example/ui/theme.dart';

void main() {
  testWidgets('the sheet closes when its handle is tapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSheet(
                context,
                builder: (_) => const Text('sheet body'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsNothing);
  });
}
