import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/grovs_platform_interface.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGrovsPlatform
    with MockPlatformInterfaceMixin
    implements GrovsPlatform {
  final enabledStates = <bool>[];
  final handledUrls = <String>[];
  GenerateLinkParams? generatedLinkParams;
  final Stream<GrovsError> errors = Stream<GrovsError>.value(
    GrovsError(
      code: GrovsErrorCode.authenticationFailed,
      message: 'Auth failed',
    ),
  ).asBroadcastStream();

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String> generateLink(GenerateLinkParams params) {
    generatedLinkParams = params;
    return Future.value('https://grovs.io/test-link');
  }

  @override
  Future<void> setSDK(bool enabled) async {
    enabledStates.add(enabled);
  }

  @override
  Future<bool> handleUrl(String url) async {
    handledUrls.add(url);
    return true;
  }

  @override
  Stream<GrovsError> get onError => errors;

  final linkDetailsPaths = <String>[];

  @override
  Future<GrovsLinkDetails> linkDetails(String path) async {
    linkDetailsPaths.add(path);
    return GrovsLinkDetails.fromMap({'path': path});
  }

  final inAppCalls = <String>[];
  final inAppEvents = const Stream<InAppMessageEvent>.empty();

  @override
  Future<void> pauseInAppMessages() async {
    inAppCalls.add('pause');
  }

  @override
  Future<void> resumeInAppMessages() async {
    inAppCalls.add('resume');
  }

  @override
  Future<void> discardInAppMessages({bool dismissCurrent = false}) async {
    inAppCalls.add('discard:$dismissCurrent');
  }

  @override
  Future<void> setInAppExcludedScreens(List<String> screens) async {
    inAppCalls.add('excluded:${screens.join(',')}');
  }

  @override
  Future<void> setInAppDebugLogging(bool enabled) async {
    inAppCalls.add('debug:$enabled');
  }

  @override
  Stream<InAppMessageEvent> get onInAppMessage => inAppEvents;

  final pushCalls = <String>[];

  @override
  Future<bool> isGrovsNotification(Map<String, dynamic> data) async {
    pushCalls.add('is:${data['k']}');
    return true;
  }

  @override
  Future<bool> handleNotificationOpen(Map<String, dynamic> data) async {
    pushCalls.add('open:${data['k']}');
    return false;
  }

  @override
  Future<void> setPushToken(String token) => Future.value();

  @override
  Future<void> setUserIdentifier(String identifier) => Future.value();

  @override
  Future<void> setUserAttributes(Map<String, dynamic> attributes) =>
      Future.value();

  @override
  Future<void> setDebugLevel(String level) => Future.value();

  @override
  Future<void> logInAppPurchase(String transactionId) => Future.value();

  @override
  Future<void> logCustomPurchase({
    required TransactionType type,
    required int priceInCents,
    required String currency,
    required String productId,
    DateTime? startDate,
  }) => Future.value();

  @override
  Future<void> track(
    String name, {
    Map<String, dynamic>? properties,
    List<String>? tags,
  }) => Future.value();

  @override
  Future<void> setGlobalTags(List<String>? tags) => Future.value();

  @override
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
  }) => Future.value();

  @override
  Future<void> setScreenAliases(Map<String, String> aliases) => Future.value();

  @override
  Stream<DeeplinkDetails> get onDeeplinkReceived => Stream.empty();
}

void main() {
  final GrovsPlatform initialPlatform = GrovsPlatform.instance;

  tearDown(() {
    GrovsPlatform.instance = initialPlatform;
  });

  test('$MethodChannelGrovs is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGrovs>());
  });

  test('getPlatformVersion', () async {
    Grovs grovsPlugin = Grovs();
    MockGrovsPlatform fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    expect(await grovsPlugin.getPlatformVersion(), '42');
  });

  test('generateLink', () async {
    Grovs grovsPlugin = Grovs();
    MockGrovsPlatform fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    final params = GenerateLinkParams(
      title: 'Test',
      copyToClipboardIos: true,
      copyToClipboardAndroid: false,
    );
    final link = await grovsPlugin.generateLink(params);

    expect(link, 'https://grovs.io/test-link');
    expect(fakePlatform.generatedLinkParams, same(params));
  });

  test('setSDK forwards enabling and disabling to the platform', () async {
    final fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    await Grovs().setSDK(false);
    await Grovs().setSDK(true);

    expect(fakePlatform.enabledStates, [false, true]);
  });

  test('handleUrl forwards the url and returns the platform result', () async {
    final fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    expect(await Grovs().handleUrl('https://example.sqd.link/abc'), isTrue);
    expect(fakePlatform.handledUrls, ['https://example.sqd.link/abc']);
  });

  test('onError forwards the platform stream', () async {
    final fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    expect(Grovs().onError, same(fakePlatform.errors));
    final error = await Grovs().onError.first;
    expect(error.code, GrovsErrorCode.authenticationFailed);
    expect(error.message, 'Auth failed');
  });

  test('in-app controls forward to the platform', () async {
    final fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    await Grovs().pauseInAppMessages();
    await Grovs().resumeInAppMessages();
    await Grovs().discardInAppMessages();
    await Grovs().discardInAppMessages(dismissCurrent: true);
    await Grovs().setInAppExcludedScreens(['A', 'B']);
    await Grovs().setInAppDebugLogging(true);

    expect(fakePlatform.inAppCalls, [
      'pause',
      'resume',
      'discard:false',
      'discard:true',
      'excluded:A,B',
      'debug:true',
    ]);
    expect(Grovs().onInAppMessage, same(fakePlatform.inAppEvents));
  });

  test('push helpers forward to the platform and return its result', () async {
    final fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    expect(await Grovs().isGrovsNotification({'k': 'a'}), isTrue);
    expect(await Grovs().handleNotificationOpen({'k': 'b'}), isFalse);
    expect(fakePlatform.pushCalls, ['is:a', 'open:b']);
  });

  test('setScreenAliases populates the static alias store', () async {
    Grovs grovsPlugin = Grovs();
    MockGrovsPlatform fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    await grovsPlugin.setScreenAliases({'/home': 'Home'});

    expect(Grovs.screenAliases, {'/home': 'Home'});
    expect(() => Grovs.screenAliases['x'] = 'y', throwsUnsupportedError);
  });

  test('linkDetails forwards the path', () async {
    final fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    final link = await Grovs().linkDetails('abc123');

    expect(link.path, 'abc123');
    expect(fakePlatform.linkDetailsPaths, ['abc123']);
  });

  for (final path in ['', '   ']) {
    test('linkDetails rejects the empty path "$path"', () async {
      final fakePlatform = MockGrovsPlatform();
      GrovsPlatform.instance = fakePlatform;

      await expectLater(
        Grovs().linkDetails(path),
        throwsA(
          isA<GrovsException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENT')
              .having((e) => e.message, 'message', 'path is required'),
        ),
      );
      expect(fakePlatform.linkDetailsPaths, isEmpty);
    });
  }
}
