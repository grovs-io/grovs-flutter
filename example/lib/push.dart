import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:url_launcher/url_launcher.dart';

import 'actions/call_code.dart';
import 'actions/log.dart';
import 'app_graph.dart';
import 'data/strings.dart';

enum NotificationStatus { unknown, allowed, notAllowed, notConfigured }

bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

/// Firebase push setup: permission status, the push token and taps on Grovs notifications.
class Push {
  Push._();

  static final status = ValueNotifier(NotificationStatus.unknown);

  static StreamSubscription<RemoteMessage>? _opened;
  static StreamSubscription<String>? _tokenRefresh;
  static AuthorizationStatus? _authorization;
  static int _run = 0;

  /// Every push token seen, so shared logs can hide them.
  static final tokens = <String>{};

  /// Asks for notification permission and finishes once the status is known.
  /// The token and the launch notification are read in the background.
  static Future<void> start() async {
    reset();
    final run = _run;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      if (run != _run) return;
      status.value = NotificationStatus.notConfigured;
      AppGraph.log.add(
        LogType.push,
        LogState.warning,
        'Push not configured',
        detail: e is FirebaseException ? e.message ?? e.code : '$e',
      );
      return;
    }
    final messaging = FirebaseMessaging.instance;
    try {
      // firebase_messaging 16.x answers every iOS notification, which hides Grovs pushes in the foreground.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.requestPermission();
      await _readStatus();
    } catch (e) {
      if (run == _run) _warn('Push setup failed', e);
      return;
    }
    if (run != _run) return;
    _opened = FirebaseMessaging.onMessageOpenedApp.listen(_logOpen);
    unawaited(_logLaunchMessage(messaging));
    unawaited(_readToken(messaging));
  }

  static Future<void> refresh() async {
    if (!_ready) return;
    try {
      await _readStatus();
    } catch (e) {
      _warn('Notification status failed', e);
      return;
    }
    await _readMissingToken();
  }

  static bool get _ready =>
      status.value == NotificationStatus.allowed ||
      status.value == NotificationStatus.notAllowed;

  static Future<void> _readStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    _authorization = settings.authorizationStatus;
    status.value = switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => NotificationStatus.allowed,
      _ => NotificationStatus.notAllowed,
    };
  }

  /// Shows the system prompt. iOS asks only once, so after a refusal this
  /// opens the app's settings instead.
  static Future<void> requestPermission() async {
    if (!_ready) return;
    final messaging = FirebaseMessaging.instance;
    try {
      if (_isIos && _authorization == AuthorizationStatus.denied) {
        await launchUrl(Uri.parse('app-settings:'));
        return;
      }
      await messaging.requestPermission();
      await _readStatus();
    } catch (e) {
      _warn('Notification permission failed', e);
      return;
    }
    await _readMissingToken();
  }

  static Future<void> _readMissingToken() async {
    if (status.value == NotificationStatus.allowed &&
        AppGraph.pushToken.value == null) {
      await _readToken(FirebaseMessaging.instance);
    }
  }

  static void reset() {
    _run++;
    unawaited(_opened?.cancel());
    unawaited(_tokenRefresh?.cancel());
    _opened = null;
    _tokenRefresh = null;
    _authorization = null;
    status.value = NotificationStatus.unknown;
  }

  static Future<void> _readToken(FirebaseMessaging messaging) async {
    if (_isIos) {
      try {
        final token = await _apnsToken(messaging);
        if (token == null) {
          AppGraph.log.add(
            LogType.push,
            LogState.warning,
            'APNs token not available yet',
            detail: 'Read again when the app returns to the foreground',
          );
          return;
        }
        _setToken(token);
        // The plugin sends the APNs token to Grovs natively.
        AppGraph.log.add(
          LogType.push,
          LogState.ok,
          'APNs token available',
          detail: middleEllipsis(token),
          code: callCode('apnsToken', [('value', token)]),
        );
      } catch (e) {
        _warn('Push token failed', e);
      }
      return;
    }

    // Listen first so a token issued while getToken runs is not missed.
    _tokenRefresh ??= messaging.onTokenRefresh.listen(_register);
    try {
      final token = await messaging.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      _warn('Push token failed', e);
    }
  }

  /// APNs registration can finish shortly after permission is granted.
  static Future<String?> _apnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 1; ; attempt++) {
      final token = await messaging.getAPNSToken();
      if (token != null || attempt == 3) return token;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  static void _setToken(String token) {
    tokens.add(token);
    AppGraph.pushToken.value = token;
  }

  static Future<void> _register(String token) async {
    final code = callCode('setPushToken', [('token', token)]);
    try {
      await Grovs().setPushToken(token);
    } catch (e) {
      AppGraph.log.add(
        LogType.push,
        LogState.error,
        'Push token failed',
        detail: '$e',
        code: code,
      );
      return;
    }
    _setToken(token);
    AppGraph.log.add(
      LogType.push,
      LogState.ok,
      'Push token registered',
      detail: middleEllipsis(token),
      code: code,
    );
  }

  static Future<void> _logLaunchMessage(FirebaseMessaging messaging) async {
    try {
      final message = await messaging.getInitialMessage();
      if (message != null) await _logOpen(message);
    } catch (e) {
      _warn('Push open failed', e);
    }
  }

  static Future<void> _logOpen(RemoteMessage message) async {
    final data = message.data;
    try {
      if (!await Grovs().isGrovsNotification(data)) return;
    } catch (e) {
      _warn('Push open failed', e);
      return;
    }
    AppGraph.log.add(
      LogType.push,
      LogState.ok,
      'Push opened',
      detail: data.keys.join(', '),
      code: callCode('pushOpen', [('data', data)]),
    );
  }

  static void _warn(String title, Object error) => AppGraph.log.add(
    LogType.push,
    LogState.warning,
    title,
    detail: error is FirebaseException ? error.message ?? error.code : '$error',
  );
}
