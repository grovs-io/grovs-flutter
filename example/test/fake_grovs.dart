import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/app_graph.dart';
import 'package:grovs_example/main.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:grovs_flutter_plugin/grovs_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _methodChannel = MethodChannel('grovs');
const _configChannel = MethodChannel('grovs_example/config');
const _deeplinks = 'grovs/deeplinks';
const _errors = 'grovs/errors';
const _inApp = 'grovs/inapp';
const _eventChannels = [_deeplinks, _errors, _inApp];
const _firebaseCore =
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore';

/// Stands in for the native Grovs SDK, the app's config channel, saved
/// settings and Firebase, so the whole app can run in a widget test.
class FakeGrovs {
  FakeGrovs._(this._originalPlatform);

  final GrovsPlatform _originalPlatform;
  final calls = <MethodCall>[];

  /// Replaces the default answer for a method, for example to fail or hang.
  final answers = <String, Future<Object?> Function(MethodCall)>{};

  List<String> get methods => [for (final call in calls) call.method];

  Map<String, dynamic> lastArgs(String method) {
    final args = calls.lastWhere((call) => call.method == method).arguments;
    return args is Map ? Map<String, dynamic>.from(args) : {};
  }

  static TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  static Future<FakeGrovs> install() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final fake = FakeGrovs._(GrovsPlatform.instance);
    GrovsPlatform.instance = MethodChannelGrovs();
    _messenger.setMockMethodCallHandler(_methodChannel, fake._answer);
    _messenger.setMockMethodCallHandler(
      _configChannel,
      (_) async => {'apiKey': 'grovst_0123456789', 'useTestEnvironment': true},
    );
    for (final name in _eventChannels) {
      _messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    _messenger.setMockMessageHandler(
      _firebaseCore,
      (_) async => const StandardMessageCodec().encodeMessage([
        'channel-error',
        'Firebase is not configured',
        null,
      ]),
    );
    return fake;
  }

  Future<Object?> _answer(MethodCall call) async {
    calls.add(call);
    final answer = answers[call.method];
    if (answer != null) return answer(call);
    return switch (call.method) {
      'generateLink' => 'https://test.sqd.link/abc',
      'linkDetails' => {
        'path': call.arguments['path'],
        'title': 'Test link',
        'access_path': 'https://test.sqd.link/${call.arguments['path']}',
        'data': {'k': 1},
      },
      'handleUrl' => true,
      _ => null,
    };
  }

  Future<void> emitDeeplink(Map<String, Object?> details) =>
      _emit(_deeplinks, details);

  Future<void> emitInApp(Map<String, Object?> event) => _emit(_inApp, event);

  Future<void> _emit(String channel, Object? data) =>
      _messenger.handlePlatformMessage(
        channel,
        const StandardMethodCodec().encodeSuccessEnvelope(data),
        (_) {},
      );

  Future<void> startApp(WidgetTester tester) async {
    await AppGraph.init(deviceName: 'Test device');
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();
  }

  void uninstall() {
    AppGraph.reset();
    GrovsPlatform.instance = _originalPlatform;
    for (final name in [
      _methodChannel.name,
      _configChannel.name,
      ..._eventChannels,
    ]) {
      _messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
    _messenger.setMockMessageHandler(_firebaseCore, null);
  }
}
