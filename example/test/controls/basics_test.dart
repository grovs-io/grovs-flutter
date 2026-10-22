import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/ui/controls/basics.dart';
import 'package:grovs_example/ui/controls/info.dart';
import 'package:grovs_example/ui/theme.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('SwitchRow toggles when the label is tapped', (tester) async {
    var value = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) =>
              SwitchRow('SDK enabled', value, (v) => setState(() => value = v)),
        ),
      ),
    );
    await tester.tap(find.text('SDK enabled'));
    await tester.pump();
    expect(value, isTrue);
  });

  testWidgets('FoldRow shows the summary only while closed', (tester) async {
    await tester.pumpWidget(
      host(
        const FoldRow('More options', 'UTM off', children: [Text('inside')]),
      ),
    );
    expect(find.text('UTM off'), findsOneWidget);
    expect(find.text('inside'), findsNothing);
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    expect(find.text('UTM off'), findsNothing);
    expect(find.text('inside'), findsOneWidget);
  });

  testWidgets('Segment reports the tapped option', (tester) async {
    String? picked;
    await tester.pumpWidget(
      host(Segment<String>(const ['Info', 'Error'], 'Info', (v) => picked = v)),
    );
    await tester.tap(find.text('Error'));
    expect(picked, 'Error');
  });

  testWidgets('a disabled AppButton ignores taps but keeps long press', (
    tester,
  ) async {
    var taps = 0, holds = 0;
    await tester.pumpWidget(
      host(
        AppButton(
          'Go',
          () => taps++,
          enabled: false,
          onLongPress: () => holds++,
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.longPress(find.text('Go'));
    expect(taps, 0);
    expect(holds, 1);
  });

  testWidgets('InfoButton opens and closes its dialog', (tester) async {
    await tester.pumpWidget(host(const InfoButton(Info('Tags', 'Labels.'))));
    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();
    expect(find.text('Labels.'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Labels.'), findsNothing);
  });
}
