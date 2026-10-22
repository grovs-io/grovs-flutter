import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:grovs_flutter_plugin/models/grovs_in_app.dart';
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

  for (final handled in <bool?>[true, false, null]) {
    test('handleUrl sends the url and returns $handled as a bool', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            captured = call;
            return handled;
          });

      final result = await platform.handleUrl('https://example.sqd.link/abc');

      expect(captured?.method, 'handleUrl');
      expect(captured?.arguments, {'url': 'https://example.sqd.link/abc'});
      expect(result, handled ?? false);
    });
  }

  test('handleUrl wraps platform errors', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'INVALID_ARGUMENT');
        });

    await expectLater(
      platform.handleUrl('not a url'),
      throwsA(
        isA<GrovsException>()
            .having((error) => error.code, 'code', 'INVALID_ARGUMENT')
            .having(
              (error) => error.message,
              'message',
              'Failed to handle URL',
            ),
      ),
    );
  });

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

  group('in-app controls', () {
    final cases = <String, ({Future<void> Function() call, Object? args})>{
      'pauseInAppMessages': (
        call: () => platform.pauseInAppMessages(),
        args: null,
      ),
      'resumeInAppMessages': (
        call: () => platform.resumeInAppMessages(),
        args: null,
      ),
      'discardInAppMessages': (
        call: () => platform.discardInAppMessages(),
        args: {'dismissCurrent': false},
      ),
      'setInAppExcludedScreens': (
        call: () => platform.setInAppExcludedScreens(['Checkout', 'Cart']),
        args: {
          'screens': ['Checkout', 'Cart'],
        },
      ),
      'setInAppDebugLogging': (
        call: () => platform.setInAppDebugLogging(true),
        args: {'enabled': true},
      ),
    };

    cases.forEach((method, testCase) {
      test('$method sends its method name and arguments', () async {
        MethodCall? captured;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              captured = call;
              return null;
            });

        await testCase.call();

        expect(captured?.method, method);
        expect(captured?.arguments, testCase.args);
      });

      test('$method wraps platform errors', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw PlatformException(code: 'IN_APP_ERROR', message: 'boom');
            });

        await expectLater(
          testCase.call(),
          throwsA(
            isA<GrovsException>()
                .having((error) => error.code, 'code', 'IN_APP_ERROR')
                .having((error) => error.message, 'message', 'boom'),
          ),
        );
      });
    });

    test('discardInAppMessages(dismissCurrent: true) sends true', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            captured = call;
            return null;
          });

      await platform.discardInAppMessages(dismissCurrent: true);

      expect(captured?.arguments, {'dismissCurrent': true});
    });
  });

  test(
    'onInAppMessage maps events, drops unknown ones and is cached',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockStreamHandler(
        const EventChannel('grovs/inapp'),
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({'type': 'shown', 'campaignId': 'c1'});
            events.success({'type': 'bogus'});
            events.success({'type': 'failed', 'message': 'm'});
            events.endOfStream();
          },
        ),
      );
      addTearDown(
        () => messenger.setMockStreamHandler(
          const EventChannel('grovs/inapp'),
          null,
        ),
      );

      final stream = platform.onInAppMessage;
      expect(identical(stream, platform.onInAppMessage), isTrue);
      expect(stream.isBroadcast, isTrue);

      final events = await stream.toList();

      expect(events, [isA<InAppMessageShown>(), isA<InAppMessageFailed>()]);
    },
  );

  for (final method in ['isGrovsNotification', 'handleNotificationOpen']) {
    final call = method == 'isGrovsNotification'
        ? platform.isGrovsNotification
        : platform.handleNotificationOpen;
    final data = {'grovs': 'yes', 'n': 1};

    for (final entry in <bool?, bool>{
      true: true,
      false: false,
      null: false,
    }.entries) {
      test(
        '$method sends data and maps ${entry.key} to ${entry.value}',
        () async {
          MethodCall? captured;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (invocation) async {
                captured = invocation;
                return entry.key;
              });

          expect(await call(data), entry.value);
          expect(captured?.method, method);
          expect(captured?.arguments, {'data': data});
        },
      );
    }

    test('$method wraps platform errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (invocation) async {
            throw PlatformException(code: 'PUSH_ERROR', message: 'boom');
          });

      await expectLater(
        call(data),
        throwsA(
          isA<GrovsException>()
              .having((error) => error.code, 'code', 'PUSH_ERROR')
              .having((error) => error.message, 'message', 'boom'),
        ),
      );
    });
  }

  group('linkDetails', () {
    void reply(Future<Object?> Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);
    }

    test('sends the path and parses the reply', () async {
      MethodCall? captured;
      reply((call) async {
        captured = call;
        return {'id': 1.0, 'path': 'abc123'};
      });

      final link = await platform.linkDetails('abc123');

      expect(captured?.method, 'linkDetails');
      expect(captured?.arguments, {'path': 'abc123'});
      expect(link.id, 1);
      expect(link.path, 'abc123');
    });

    test('sends the path unchanged', () async {
      MethodCall? captured;
      reply((call) async {
        captured = call;
        return <String, Object?>{};
      });

      await platform.linkDetails('/abc123 ');

      expect(captured?.arguments, {'path': '/abc123 '});
    });

    test('maps platform errors', () async {
      reply((call) async {
        throw PlatformException(
          code: 'SDK_DISABLED',
          message: 'Grovs SDK is disabled. Call setSDK(true) first.',
        );
      });

      expect(
        platform.linkDetails('abc123'),
        throwsA(
          isA<GrovsException>()
              .having((e) => e.code, 'code', 'SDK_DISABLED')
              .having(
                (e) => e.message,
                'message',
                'Grovs SDK is disabled. Call setSDK(true) first.',
              ),
        ),
      );
    });

    test('null reply is an error', () async {
      reply((call) async => null);

      expect(
        platform.linkDetails('abc123'),
        throwsA(
          isA<GrovsException>().having(
            (e) => e.code,
            'code',
            'LINK_DETAILS_ERROR',
          ),
        ),
      );
    });
  });
}
