import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'grovs_platform_interface.dart';

/// An implementation of [GrovsPlatform] that uses method channels.
class MethodChannelGrovs extends GrovsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('grovs');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
