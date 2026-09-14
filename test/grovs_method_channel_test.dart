import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGrovs platform = MethodChannelGrovs();
  const MethodChannel channel = MethodChannel('grovs');

  setUp(() {
    platform = MethodChannelGrovs();
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

  for (final enabled in [true, false]) {
    test('setSDK sends enabled=$enabled', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            captured = call;
            return null;
          });

      await platform.setSDK(enabled);

      expect(captured?.method, 'setSDK');
      expect(captured?.arguments, {'enabled': enabled});
    });
  }

  for (final message in <String?>['Native failure', null]) {
    test('setSDK wraps platform errors with message $message', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'SDK_ERROR', message: message);
          });

      await expectLater(
        platform.setSDK(false),
        throwsA(
          isA<GrovsException>()
              .having((error) => error.code, 'code', 'SDK_ERROR')
              .having(
                (error) => error.message,
                'message',
                message ?? 'Failed to set SDK enabled state',
              ),
        ),
      );
    });
  }

  for (final copyToClipboard in <bool?>[true, false, null]) {
    test('generateLink sends clipboard value $copyToClipboard', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            captured = call;
            return 'https://example.grovs.io/product';
          });
      final params = GenerateLinkParams(
        title: 'Product',
        data: {'id': '123'},
        showPreviewIos: false,
        showPreviewAndroid: true,
        copyToClipboardIos: copyToClipboard,
        copyToClipboardAndroid: copyToClipboard,
      );

      expect(
        await platform.generateLink(params),
        'https://example.grovs.io/product',
      );
      expect(captured?.method, 'generateLink');
      expect(captured?.arguments, params.toMap());
      expect(
        captured?.arguments,
        containsPair('copyToClipboardIos', copyToClipboard),
      );
      expect(
        captured?.arguments,
        containsPair('copyToClipboardAndroid', copyToClipboard),
      );
      expect(captured?.arguments, containsPair('data', {'id': '123'}));
      expect(captured?.arguments, containsPair('showPreviewIos', false));
      expect(captured?.arguments, containsPair('showPreviewAndroid', true));
    });
  }

  test('onError maps known codes and shares one native subscription', () async {
    const errorMethods = MethodChannel('grovs/errors');
    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(errorMethods, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(errorMethods, null));

    expect(platform.errorChannel.name, 'grovs/errors');
    final stream = platform.onError;
    expect(identical(stream, platform.onError), isTrue);
    expect(stream.isBroadcast, isTrue);
    final first = <GrovsError>[];
    final second = <GrovsError>[];
    final firstSubscription = stream.listen(first.add);
    final secondSubscription = platform.onError.listen(second.add);
    addTearDown(firstSubscription.cancel);
    addTearDown(secondSubscription.cancel);
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['listen']);

    for (final code in GrovsErrorCode.values) {
      await messenger.handlePlatformMessage(
        'grovs/errors',
        codec.encodeSuccessEnvelope({
          'code': code.nativeName,
          'message': code.name,
        }),
        (_) {},
      );
    }
    await messenger.handlePlatformMessage(
      'grovs/errors',
      codec.encodeSuccessEnvelope({
        'code': 'future_error',
        'message': 'Ignore',
      }),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      'grovs/errors',
      codec.encodeSuccessEnvelope({'message': 'Missing code'}),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(first.map((error) => error.code), GrovsErrorCode.values);
    expect(second.map((error) => error.code), GrovsErrorCode.values);
    expect(
      first.map((error) => error.message),
      GrovsErrorCode.values.map((code) => code.name),
    );
    await firstSubscription.cancel();
    expect(calls, ['listen']);
    await secondSubscription.cancel();
    expect(calls, ['listen', 'cancel']);
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

  test('trackScreenView sends correct method and arguments', () async {
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          captured = call;
          return null;
        });

    await platform.trackScreenView('Checkout', properties: {'step': 2});

    expect(captured?.method, 'trackScreenView');
    expect(captured?.arguments, {
      'screenName': 'Checkout',
      'properties': {'step': 2},
    });
  });

  for (final startDate in <DateTime?>[
    DateTime.utc(2026, 9, 14, 10, 30, 15, 250),
    DateTime(2026, 9, 14, 10, 30),
    null,
  ]) {
    test('logCustomPurchase sends startDate $startDate as epoch ms', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            captured = call;
            return null;
          });

      await platform.logCustomPurchase(
        type: TransactionType.buy,
        priceInCents: 999,
        currency: 'USD',
        productId: 'pro',
        startDate: startDate,
      );

      expect(captured?.method, 'logCustomPurchase');
      expect(captured?.arguments, {
        'type': 'buy',
        'priceInCents': 999,
        'currency': 'USD',
        'productId': 'pro',
        'startDate': startDate?.millisecondsSinceEpoch,
      });
    });
  }

  test('setScreenAliases sends correct method and arguments', () async {
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          captured = call;
          return null;
        });

    await platform.setScreenAliases({'/home': 'Home', '/cart': 'Cart'});

    expect(captured?.method, 'setScreenAliases');
    expect(captured?.arguments, {
      'aliases': {'/home': 'Home', '/cart': 'Cart'},
    });
  });
}
