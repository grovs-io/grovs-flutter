import 'package:flutter/services.dart';

/// The Grovs settings the plugin reads natively from Info.plist and the
/// Android manifest, so the app can show what the SDK was configured with.
class NativeConfig {
  const NativeConfig({
    required this.apiKey,
    this.useTestEnvironment = false,
    this.baseUrl,
    this.clipboardDomains = const [],
    this.startEnabled = true,
  });

  static const unknown = NativeConfig(apiKey: '');

  static const _channel = MethodChannel('grovs_example/config');

  final String apiKey;
  final bool useTestEnvironment;
  final String? baseUrl;
  final List<String> clipboardDomains;
  final bool startEnabled;

  static Future<NativeConfig> read() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>('read');
      if (map == null) return unknown;
      final domains = map['clipboardDomains'];
      return NativeConfig(
        apiKey: map['apiKey'] as String? ?? '',
        useTestEnvironment: map['useTestEnvironment'] as bool? ?? false,
        baseUrl: map['baseUrl'] as String?,
        clipboardDomains: domains is List
            ? domains.whereType<String>().toList()
            : const [],
        startEnabled: map['startEnabled'] as bool? ?? true,
      );
    } catch (_) {
      return unknown;
    }
  }
}
