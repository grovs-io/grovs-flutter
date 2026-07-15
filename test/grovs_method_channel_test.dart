import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGrovs platform = MethodChannelGrovs();
  const MethodChannel channel = MethodChannel('grovs');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('track sends correct method and arguments', () async {
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      captured = call;
      return null;
    });

    await platform.track(
      'signup_completed',
      properties: {'plan': 'pro'},
      tags: ['onboarding'],
    );

    expect(captured?.method, 'track');
    expect(captured?.arguments, {
      'name': 'signup_completed',
      'properties': {'plan': 'pro'},
      'tags': ['onboarding'],
    });
  });

  test('setGlobalTags sends correct method and arguments', () async {
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      captured = call;
      return null;
    });

    await platform.setGlobalTags(['premium', 'beta']);

    expect(captured?.method, 'setGlobalTags');
    expect(captured?.arguments, {
      'tags': ['premium', 'beta'],
    });
  });
}
