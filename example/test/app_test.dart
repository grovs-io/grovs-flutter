import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/log.dart';
import 'package:grovs_example/app_graph.dart';
import 'fake_grovs.dart';

void main() {
  late FakeGrovs grovs;
  setUp(() async => grovs = await FakeGrovs.install());
  tearDown(() => grovs.uninstall());

  testWidgets(
    'starts on Home, switches tabs and shows the newest log in the strip',
    (tester) async {
      await grovs.startApp(tester);
      expect(find.text('Grovs Test'), findsOneWidget);
      expect(find.text('SDK configured'), findsOneWidget);
      await tester.tap(find.text('Links'));
      await tester.pumpAndSettle();
      expect(find.text('Links'), findsNWidgets(2));
    },
  );

  testWidgets('the strip opens the logs panel and a deep link shows up', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await grovs.emitDeeplink({
      'link': 'https://test.sqd.link/abc',
      'data': {'k': 1},
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opened from link').last);
    await tester.pumpAndSettle();
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('abc · received'), findsOneWidget);
  });

  testWidgets('startup applies saved state to the SDK', (tester) async {
    await grovs.startApp(tester);
    expect(
      grovs.methods,
      containsAll([
        'setDebugLevel',
        'setUserIdentifier',
        'setUserAttributes',
        'setGlobalTags',
        'setScreenAliases',
        'setInAppExcludedScreens',
        'setInAppDebugLogging',
      ]),
    );
  });

  Future<void> openLogs(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open logs'));
    await tester.pumpAndSettle();
  }

  testWidgets('a row opens its detail and back returns to the list', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await openLogs(tester);

    await tester.tap(find.text('SDK configured').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('configure('), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Run again'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Logs'), findsOneWidget);
  });

  testWidgets(
    'opening on an entry shows its detail, closing resets the panel',
    (tester) async {
      await grovs.startApp(tester);
      final entry = AppGraph.log.add(
        LogType.event,
        LogState.error,
        'Track failed',
        code: 'track()',
      );
      AppGraph.openPanel(entry.id);
      await tester.pumpAndSettle();
      expect(find.text('track()'), findsOneWidget);
      expect(AppGraph.log.unseenError, isFalse);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('track()'), findsNothing);
      expect(AppGraph.panel.value.open, isFalse);
    },
  );

  testWidgets('errors show a count on their filter and clear empties the log', (
    tester,
  ) async {
    await grovs.startApp(tester);
    AppGraph.log.add(LogType.event, LogState.error, 'Track failed');
    await openLogs(tester);
    expect(find.text('Errors 1'), findsOneWidget);
    expect(find.text('SDK configured'), findsOneWidget);

    await tester.tap(find.text('Errors 1'));
    await tester.pumpAndSettle();
    expect(find.text('Track failed'), findsNWidgets(2));
    expect(find.text('SDK configured'), findsNothing);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged yet'), findsOneWidget);
  });

  testWidgets('the strip and tab bar step aside while the keyboard is open', (
    tester,
  ) async {
    await grovs.startApp(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open logs'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the gear opens Settings', (tester) async {
    await grovs.startApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Grovs Test'), findsNothing);
  });

  testWidgets('Generate link shows the result card and a log entry', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('Links'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate link'));
    await tester.pumpAndSettle();
    expect(find.text('https://test.sqd.link/abc'), findsOneWidget);
    expect(find.text('QR'), findsOneWidget);
    expect(AppGraph.log.entries.first.title, 'Generate link');
  });

  testWidgets('Inspect on the result card opens the new inspect entry', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('Links'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inspect'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('linkDetails')['path'], 'abc');
    expect(find.textContaining('linkDetails('), findsOneWidget);
    AppGraph.closePanel();
    await tester.pumpAndSettle();
  });

  testWidgets('Inspect link from a log detail shows the inspect entry', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await grovs.emitDeeplink({'link': 'https://test.sqd.link/abc'});
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opened from link').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inspect link'));
    await tester.pumpAndSettle();
    expect(find.text('Inspect link'), findsNothing);
    expect(find.textContaining('linkDetails('), findsOneWidget);
    AppGraph.closePanel();
    await tester.pumpAndSettle();
  });

  testWidgets('closing the panel from outside closes the sheet', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.tap(find.byTooltip('Open logs'));
    await tester.pumpAndSettle();
    expect(find.text('Logs'), findsOneWidget);
    AppGraph.closePanel();
    await tester.pumpAndSettle();
    expect(find.text('Logs'), findsNothing);
  });

  testWidgets('the QR sheet shows the link and the copy actions', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('Links'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QR'));
    await tester.pumpAndSettle();
    expect(find.text('Scan on another phone'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Copy adb'), findsOneWidget);
  });

  testWidgets('a reserved event name blocks Track and offers Send anyway', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'install');
    await tester.pump();
    expect(find.text('"install" is reserved by the SDK'), findsWidgets);
    await tester.tap(find.text('Send anyway'));
    await tester.pumpAndSettle();
    expect(grovs.methods.where((m) => m == 'track'), isNotEmpty);
    expect(grovs.lastArgs('track')['name'], 'install');
  });

  testWidgets('Track sends the saved sample event', (tester) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track').first);
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('track')['name'], 'demo_tapped');
  });

  testWidgets('the purchase button logs the sample purchase', (tester) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Log \$4.99'));
    await tester.tap(find.textContaining('Log \$4.99'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('logCustomPurchase')['priceInCents'], 499);
  });
}
