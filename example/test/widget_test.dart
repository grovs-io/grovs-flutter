import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/main.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:grovs_flutter_plugin/grovs_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methodChannel = MethodChannel('grovs');
  const streamChannels = ['grovs/deeplinks', 'grovs/errors', 'grovs/inapp'];
  late GrovsPlatform originalPlatform;
  late List<MethodCall> methodCalls;
  late Map<String, List<String>> streamCalls;
  Future<void> Function(bool enabled)? setSDK;

  setUp(() {
    originalPlatform = GrovsPlatform.instance;
    GrovsPlatform.instance = MethodChannelGrovs();
    methodCalls = [];
    streamCalls = {for (final channel in streamChannels) channel: []};
    setSDK = null;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      methodCalls.add(call);
      if (call.method == 'getPlatformVersion') return 'Test OS 1.0';
      if (call.method == 'setSDK') {
        await setSDK?.call(call.arguments['enabled'] as bool);
      }
      return null;
    });
    for (final channel in streamChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (call) async {
        streamCalls[channel]!.add(call.method);
        return null;
      });
    }
  });

  tearDown(() {
    GrovsPlatform.instance = originalPlatform;
    messenger.setMockMethodCallHandler(methodChannel, null);
    for (final channel in streamChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  Future<void> pumpApp(WidgetTester tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  }

  final consentTile = find.widgetWithText(SwitchListTile, 'SDK enabled');

  SwitchListTile consentSwitch(WidgetTester tester) =>
      tester.widget<SwitchListTile>(consentTile);

  Future<void> tapConsent(WidgetTester tester) async {
    await tester.ensureVisible(consentTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: consentTile, matching: find.byType(Switch)),
    );
    await tester.pump();
  }

  testWidgets('renders the platform version and subscribes to SDK events', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Running on: Test OS 1.0'), findsOneWidget);
    expect(consentSwitch(tester).value, isTrue);
    expect(streamCalls['grovs/deeplinks'], ['listen']);
    expect(streamCalls['grovs/inapp'], ['listen']);
    expect(streamCalls['grovs/errors'], ['listen']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes consent only after the native operation succeeds', (
    tester,
  ) async {
    final pendingDisable = Completer<void>();
    setSDK = (enabled) async {
      if (!enabled) await pendingDisable.future;
    };
    await pumpApp(tester);

    await tapConsent(tester);
    expect(consentSwitch(tester).value, isTrue);
    expect(consentSwitch(tester).onChanged, isNull);
    expect(
      methodCalls.where((call) => call.method == 'setSDK').single.arguments,
      {'enabled': false},
    );

    pendingDisable.complete();
    await tester.pumpAndSettle();
    expect(consentSwitch(tester).value, isFalse);
    expect(consentSwitch(tester).onChanged, isNotNull);

    await tapConsent(tester);
    await tester.pumpAndSettle();
    expect(consentSwitch(tester).value, isTrue);
    expect(
      methodCalls
          .where((call) => call.method == 'setSDK')
          .map((call) => call.arguments),
      [
        {'enabled': false},
        {'enabled': true},
      ],
    );
  });

  testWidgets('keeps consent unchanged and displays native failures', (
    tester,
  ) async {
    setSDK = (_) async {
      throw PlatformException(
        code: 'consent_failed',
        message: 'Could not update consent',
      );
    };
    await pumpApp(tester);

    await tapConsent(tester);
    await tester.pumpAndSettle();

    expect(consentSwitch(tester).value, isTrue);
    expect(consentSwitch(tester).onChanged, isNotNull);
    expect(
      find.text(
        'GrovsException: Could not update consent (code: consent_failed)',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('displays the latest SDK error received from the event stream', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final message in ['First failure', 'Latest failure']) {
      await messenger.handlePlatformMessage(
        'grovs/errors',
        const StandardMethodCodec().encodeSuccessEnvelope({
          'code': 'network_request_failed',
          'message': message,
        }),
        (_) {},
      );
      await tester.pump();
      expect(find.text('network_request_failed: $message'), findsOneWidget);
    }
    expect(find.text('network_request_failed: First failure'), findsNothing);
  });

  testWidgets('shows that push is not configured without Firebase files', (
    tester,
  ) async {
    const firebaseCoreChannel =
        'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore';
    messenger.setMockMessageHandler(
      firebaseCoreChannel,
      (_) async => const StandardMessageCodec().encodeMessage([
        'channel-error',
        'Firebase is not configured',
        null,
      ]),
    );
    addTearDown(
      () => messenger.setMockMessageHandler(firebaseCoreChannel, null),
    );
    await pumpApp(tester);

    expect(find.text('Push not configured'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logs in-app message events and pauses messages', (tester) async {
    await pumpApp(tester);

    await messenger.handlePlatformMessage(
      'grovs/inapp',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'type': 'shown',
        'campaignId': 'c1',
      }),
      (_) {},
    );
    await tester.pump();
    expect(find.text('shown c1'), findsOneWidget);

    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(
      methodCalls.map((call) => call.method),
      contains('pauseInAppMessages'),
    );
    expect(find.text('paused'), findsOneWidget);
  });

  testWidgets(
    'cancels SDK streams and safely completes consent after disposal',
    (tester) async {
      final pendingDisable = Completer<void>();
      setSDK = (_) => pendingDisable.future;
      await pumpApp(tester);
      await tapConsent(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(streamCalls['grovs/deeplinks'], ['listen', 'cancel']);
      expect(streamCalls['grovs/errors'], ['listen', 'cancel']);

      pendingDisable.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
