import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'grovs_method_channel.dart';

abstract class GrovsPlatform extends PlatformInterface {
  /// Constructs a GrovsPlatform.
  GrovsPlatform() : super(token: _token);

  static final Object _token = Object();

  static GrovsPlatform _instance = MethodChannelGrovs();

  /// The default instance of [GrovsPlatform] to use.
  ///
  /// Defaults to [MethodChannelGrovs].
  static GrovsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GrovsPlatform] when
  /// they register themselves.
  static set instance(GrovsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
