import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/log.dart';
import 'package:grovs_example/app_graph.dart';
import 'package:grovs_example/ui/in_app/in_app_screen.dart';
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
      expect(find.text('Push not configured'), findsOneWidget);
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

  testWidgets('settings shows the native config and changes debug level', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('setDebugLevel')['level'], 'error');
    expect(AppGraph.log.entries.first.title, 'Debug level ERROR');
    expect(AppGraph.store.debugLevel, 'error');
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

  testWidgets('in-app controls call the SDK and discard pauses', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('In-app'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard waiting'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('discardInAppMessages')['dismissCurrent'], isFalse);
    await tester.tap(find.text('Running'));
    await tester.pumpAndSettle();
    expect(grovs.methods.last, 'resumeInAppMessages');
  });

  testWidgets('in-app events are logged', (tester) async {
    await grovs.startApp(tester);
    await grovs.emitInApp({'type': 'shown', 'campaignId': '42'});
    await tester.pumpAndSettle();
    expect(find.text('Message 42 shown'), findsOneWidget);
  });

  testWidgets('the excluded screen opens as a named route', (tester) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('In-app'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Open an excluded screen'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(InAppScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Open an excluded screen'));
    await tester.pumpAndSettle();
    expect(find.text('excluded'), findsOneWidget);
    expect(grovs.lastArgs('trackScreenView')['screenName'], 'ExcludedScreen');
  });

  testWidgets('SDK switch calls setSDK and logs it', (tester) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('SDK enabled'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('setSDK')['enabled'], isFalse);
    expect(find.text('SDK disabled'), findsOneWidget);
  });

  testWidgets('a failing setSDK is logged and the switch turns back', (
    tester,
  ) async {
    grovs.answers['setSDK'] = (_) async => throw PlatformException(
      code: 'consent_failed',
      message: 'Could not update consent',
    );
    await grovs.startApp(tester);
    await tester.tap(find.text('SDK enabled'));
    await tester.pumpAndSettle();
    final entry = AppGraph.log.entries.first;
    expect(entry.title, 'SDK disabled');
    expect(entry.state, LogState.error);
    expect(entry.detail, contains('Could not update consent'));
    expect(AppGraph.sdkEnabled.value, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending setSDK completes safely after Home is gone', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    grovs.answers['setSDK'] = (_) => pending.future;
    await grovs.startApp(tester);
    await tester.tap(find.text('SDK enabled'));
    await tester.pump();
    expect(AppGraph.sdkEnabled.value, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(AppGraph.log.entries.first.title, 'SDK disabled');
    expect(AppGraph.log.entries.first.state, LogState.ok);
    expect(tester.takeException(), isNull);
  });

  testWidgets('identity save sends identifier and attributes', (tester) async {
    await grovs.startApp(tester);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('qa_user_1'));
    await tester.tap(find.text('qa_user_1'));
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('setUserIdentifier')['identifier'], 'qa_user_1');
  });

  testWidgets('saving no identifier only sends attributes and warns', (
    tester,
  ) async {
    await grovs.startApp(tester);
    final before = grovs.methods.length;
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('None'));
    await tester.tap(find.text('None'));
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(grovs.methods.skip(before), ['setUserAttributes']);
    final entry = AppGraph.log.entries.first;
    expect(entry.state, LogState.warning);
    expect(entry.detail, contains('the plugin cannot clear an identifier'));
    expect(find.text('None'), findsOneWidget);
  });

  testWidgets('without Firebase files push shows Not configured', (
    tester,
  ) async {
    await grovs.startApp(tester);
    expect(find.text('Not configured'), findsOneWidget);
  });

  testWidgets('quick action Generate link runs with saved values', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.ensureVisible(find.text('Generate link'));
    await tester.tap(find.text('Generate link'));
    await tester.pumpAndSettle();
    expect(grovs.methods, contains('generateLink'));
  });

  void mockClipboard(WidgetTester tester, String? text) {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': text} : null,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }

  testWidgets('Open clipboard without a link says so', (tester) async {
    await grovs.startApp(tester);
    mockClipboard(tester, 'hello');
    await tester.ensureVisible(find.text('Open clipboard'));
    await tester.tap(find.text('Open clipboard'));
    await tester.pump();
    expect(find.text('Clipboard has no link'), findsOneWidget);
    expect(grovs.methods, isNot(contains('handleUrl')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('Open clipboard opens a copied link in the app', (tester) async {
    await grovs.startApp(tester);
    mockClipboard(tester, ' https://test.sqd.link/abc ');
    await tester.ensureVisible(find.text('Open clipboard'));
    await tester.tap(find.text('Open clipboard'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('handleUrl')['url'], 'https://test.sqd.link/abc');
  });

  testWidgets('holding Track opens the event form and tracks from it', (
    tester,
  ) async {
    await grovs.startApp(tester);
    await tester.ensureVisible(find.text('Track demo_tapped'));
    await tester.longPress(find.text('Track demo_tapped'));
    await tester.pumpAndSettle();
    expect(find.text('Track event'), findsOneWidget);
    await tester.tap(find.text('Save and track'));
    await tester.pumpAndSettle();
    expect(grovs.lastArgs('track')['name'], 'demo_tapped');
    expect(find.text('Track event'), findsNothing);
  });

  testWidgets('Opened from shows the last link and opens its log entry', (
    tester,
  ) async {
    await grovs.startApp(tester);
    expect(find.text('Not opened from a link yet'), findsOneWidget);
    await grovs.emitDeeplink({'link': 'https://test.sqd.link/abc'});
    await tester.pumpAndSettle();
    expect(find.text('just now'), findsOneWidget);
    expect(find.text('received'), findsOneWidget);
    await tester.tap(find.text('https://test.sqd.link/abc'));
    await tester.pumpAndSettle();
    expect(find.textContaining('onDeeplinkReceived('), findsOneWidget);
    AppGraph.closePanel();
    await tester.pumpAndSettle();
  });
}
