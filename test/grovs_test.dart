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
  Stream<GrovsError> get onError => errors;

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

  test('onError forwards the platform stream', () async {
    final fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    expect(Grovs().onError, same(fakePlatform.errors));
    final error = await Grovs().onError.first;
    expect(error.code, GrovsErrorCode.authenticationFailed);
    expect(error.message, 'Auth failed');
  });

  test('setScreenAliases populates the static alias store', () async {
    Grovs grovsPlugin = Grovs();
    MockGrovsPlatform fakePlatform = MockGrovsPlatform();
    GrovsPlatform.instance = fakePlatform;

    await grovsPlugin.setScreenAliases({'/home': 'Home'});

    expect(Grovs.screenAliases, {'/home': 'Home'});
    expect(() => Grovs.screenAliases['x'] = 'y', throwsUnsupportedError);
  });
}
