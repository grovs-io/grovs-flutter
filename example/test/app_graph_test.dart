import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/log.dart';
import 'package:grovs_example/app_graph.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:grovs_flutter_plugin/grovs_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const grovs = MethodChannel('grovs');
  const config = MethodChannel('grovs_example/config');
  const streams = ['grovs/deeplinks', 'grovs/errors', 'grovs/inapp'];
  late GrovsPlatform originalPlatform;
  late List<String> calls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    originalPlatform = GrovsPlatform.instance;
    GrovsPlatform.instance = MethodChannelGrovs();
    calls = [];
    messenger.setMockMethodCallHandler(grovs, (call) async {
      calls.add(call.method);
      if (call.method == 'setGlobalTags') {
        throw PlatformException(code: 'tags_failed', message: 'No tags');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      config,
      (_) async => {'apiKey': 'grovst_0123456789', 'useTestEnvironment': true},
    );
    for (final name in streams) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
  });

  tearDown(() {
    AppGraph.reset();
    GrovsPlatform.instance = originalPlatform;
    for (final name in [grovs.name, config.name, ...streams]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  });

  test('pluginVersion matches the plugin pubspec', () {
    final pubspec = File('../pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('\nversion: $pluginVersion\n'));
  });

  test('applies saved settings and keeps going past a failing call', () async {
    await AppGraph.init(deviceName: '@Test phone');

    expect(calls, [
      'setDebugLevel',
      'setUserIdentifier',
      'setUserAttributes',
      'setGlobalTags',
      'setScreenAliases',
      'setInAppExcludedScreens',
      'setInAppDebugLogging',
    ]);
    final entries = AppGraph.log.entries;
    expect(
      entries.where((e) => e.state == LogState.error).single.title,
      'Global tags set',
    );
    expect(entries.first.title, 'SDK configured');
    expect(entries.first.detail, 'test · natively');
    expect(entries.first.code, contains('"grovs…56789"'));
  });

  test(
    'flags a missing API key instead of reporting a configured SDK',
    () async {
      messenger.setMockMethodCallHandler(config, (_) async => {'apiKey': ''});

      await AppGraph.init(deviceName: '@Test phone');

      final entry = AppGraph.log.entries.first;
      expect(entry.state, LogState.warning);
      expect(entry.title, 'SDK not configured');
      expect(entry.detail, contains('AndroidManifest.xml'));
    },
  );

  test('logs an incoming deep link', () async {
    await AppGraph.init(deviceName: '@Test phone');

    await messenger.handlePlatformMessage(
      'grovs/deeplinks',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'link': 'https://app.sqd.link/abc',
        'data': {'screen': 'product'},
      }),
      (_) {},
    );

    final entry = AppGraph.log.entries.first;
    expect(entry.type, LogType.link);
    expect(entry.link, 'https://app.sqd.link/abc');
  });

  test('logs SDK errors and in-app events from their streams', () async {
    await AppGraph.init(deviceName: '@Test phone');

    await messenger.handlePlatformMessage(
      'grovs/errors',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'code': 'network_request_failed',
        'message': 'Offline',
      }),
      (_) {},
    );
    var entry = AppGraph.log.entries.first;
    expect(entry.state, LogState.error);
    expect(entry.title, 'network_request_failed');
    expect(entry.detail, 'Offline');

    await messenger.handlePlatformMessage(
      'grovs/inapp',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'type': 'shown',
        'campaignId': 'c1',
      }),
      (_) {},
    );
    entry = AppGraph.log.entries.first;
    expect(entry.type, LogType.inApp);
    expect(entry.title, 'Message c1 shown');
  });
}
