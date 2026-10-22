import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

class PushSection extends StatefulWidget {
  const PushSection({super.key});

  @override
  State<PushSection> createState() => _PushSectionState();
}

class _PushSectionState extends State<PushSection> {
  final _grovs = Grovs();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String _status = 'Starting push';
  String _lastTap = 'None';

  @override
  void initState() {
    super.initState();
    _setUpPush();
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _openedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setUpPush() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      _setStatus('Push not configured');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    // firebase_messaging 16.x answers every iOS notification, which hides Grovs pushes in the foreground.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _setStatus('Push permission denied');
      return;
    }

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_markTap);
    await _sendToken(messaging);
  }

  Future<void> _sendToken(FirebaseMessaging messaging) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final token = await messaging.getAPNSToken();
        _setStatus(
          token == null
              ? 'APNs token not available yet'
              : 'APNs token sent by the plugin',
        );
      } on FirebaseException catch (e) {
        _setStatus('APNs token failed: ${e.message}');
      }
      return;
    }

    if (!mounted) return;
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(_setPushToken);
    try {
      final token = await messaging.getToken();
      if (token == null) {
        _setStatus('FCM token not available yet');
      } else {
        await _setPushToken(token);
      }
    } on FirebaseException catch (e) {
      _setStatus('FCM token failed: ${e.message}');
    }
  }

  Future<void> _setPushToken(String token) async {
    try {
      await _grovs.setPushToken(token);
      _setStatus('FCM token sent');
    } on GrovsException catch (e) {
      _setStatus('Token failed: ${e.message}');
    }
  }

  Future<void> _markTap(RemoteMessage message) async {
    final isGrovs = await _grovs.isGrovsNotification(message.data);
    if (!mounted) return;
    setState(() {
      _lastTap = isGrovs ? 'Grovs notification' : 'Other notification';
    });
  }

  void _setStatus(String status) {
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Push',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 8),
            const Text(
              'Last notification tap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_lastTap, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
