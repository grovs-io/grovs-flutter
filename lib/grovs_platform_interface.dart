import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'grovs_method_channel.dart';
import 'models/grovs_link.dart';

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

  /// Generate a Grovs link with the specified parameters
  Future<String> generateLink(GenerateLinkParams params) {
    throw UnimplementedError('generateLink() has not been implemented.');
  }

  /// Set the push token for receiving push notifications
  Future<void> setPushToken(String token) {
    throw UnimplementedError('setPushToken() has not been implemented.');
  }

  /// Set user identifier
  Future<void> setUserIdentifier(String identifier) {
    throw UnimplementedError('setUserIdentifier() has not been implemented.');
  }

  /// Set user attributes
  Future<void> setUserAttributes(Map<String, dynamic> attributes) {
    throw UnimplementedError('setUserAttributes() has not been implemented.');
  }

  /// Set debug level
  Future<void> setDebugLevel(String level) {
    throw UnimplementedError('setDebugLevel() has not been implemented.');
  }

  /// Stream of deeplink events
  Stream<DeeplinkDetails> get onDeeplinkReceived {
    throw UnimplementedError('onDeeplinkReceived has not been implemented.');
  }
}
