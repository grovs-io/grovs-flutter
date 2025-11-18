import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/grovs_platform_interface.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGrovsPlatform
    with MockPlatformInterfaceMixin
    implements GrovsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String> generateLink(GenerateLinkParams params) =>
      Future.value('https://grovs.io/test-link');

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
  Stream<DeeplinkDetails> get onDeeplinkReceived => Stream.empty();
}

void main() {
  final GrovsPlatform initialPlatform = GrovsPlatform.instance;

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

    final link = await grovsPlugin.generateLink(
      GenerateLinkParams(title: 'Test'),
    );

    expect(link, 'https://grovs.io/test-link');
  });
}
