import 'package:flutter_test/flutter_test.dart';
import 'package:grovs/grovs.dart';
import 'package:grovs/grovs_platform_interface.dart';
import 'package:grovs/grovs_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGrovsPlatform
    with MockPlatformInterfaceMixin
    implements GrovsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
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
}
