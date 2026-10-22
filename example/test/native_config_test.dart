import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/native_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('grovs_example/config');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reads the values the native side returns', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {
        'apiKey': 'grovst_abc',
        'useTestEnvironment': true,
        'baseUrl': null,
        'clipboardDomains': ['a.b'],
        'startEnabled': false,
      },
    );
    final config = await NativeConfig.read();
    expect(config.apiKey, 'grovst_abc');
    expect(config.useTestEnvironment, isTrue);
    expect(config.clipboardDomains, ['a.b']);
    expect(config.startEnabled, isFalse);
  });

  test('falls back when the channel is missing', () async {
    final config = await NativeConfig.read();
    expect(config.apiKey, '');
    expect(config.startEnabled, isTrue);
  });
}
