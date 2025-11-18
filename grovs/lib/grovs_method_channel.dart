import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'grovs_platform_interface.dart';
import 'models/grovs_link.dart';

/// An implementation of [GrovsPlatform] that uses method channels.
class MethodChannelGrovs extends GrovsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('grovs');

  /// The event channel for receiving deeplink events
  @visibleForTesting
  final eventChannel = const EventChannel('grovs/deeplinks');

  Stream<DeeplinkDetails>? _onDeeplinkReceived;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<String> generateLink(GenerateLinkParams params) async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'generateLink',
        params.toMap(),
      );
      if (result == null) {
        throw GrovsException('Failed to generate link: null result');
      }
      return result;
    } on PlatformException catch (e) {
      throw GrovsException(
        e.message ?? 'Failed to generate link',
        code: e.code,
      );
    }
  }

  @override
  Future<void> setPushToken(String token) async {
    try {
      await methodChannel.invokeMethod('setPushToken', {'token': token});
    } on PlatformException catch (e) {
      throw GrovsException(
        e.message ?? 'Failed to set push token',
        code: e.code,
      );
    }
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    try {
      await methodChannel.invokeMethod('setUserIdentifier', {
        'identifier': identifier,
      });
    } on PlatformException catch (e) {
      throw GrovsException(
        e.message ?? 'Failed to set user identifier',
        code: e.code,
      );
    }
  }

  @override
  Future<void> setUserAttributes(Map<String, dynamic> attributes) async {
    try {
      await methodChannel.invokeMethod('setUserAttributes', {
        'attributes': attributes,
      });
    } on PlatformException catch (e) {
      throw GrovsException(
        e.message ?? 'Failed to set user attributes',
        code: e.code,
      );
    }
  }

  @override
  Future<void> setDebugLevel(String level) async {
    try {
      await methodChannel.invokeMethod('setDebugLevel', {'level': level});
    } on PlatformException catch (e) {
      throw GrovsException(
        e.message ?? 'Failed to set debug level',
        code: e.code,
      );
    }
  }

  @override
  Stream<DeeplinkDetails> get onDeeplinkReceived {
    _onDeeplinkReceived ??= eventChannel.receiveBroadcastStream().map((
      dynamic event,
    ) {
      return DeeplinkDetails.fromMap(event as Map<dynamic, dynamic>);
    });
    return _onDeeplinkReceived!;
  }
}
