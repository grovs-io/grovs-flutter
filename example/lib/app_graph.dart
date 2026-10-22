import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:grovs_flutter_plugin/grovs.dart';

import 'actions/call_code.dart';
import 'actions/log.dart';
import 'actions/test_log.dart';
import 'actions/test_runner.dart';
import 'data/key_value.dart';
import 'data/settings_store.dart';
import 'data/strings.dart';
import 'native_config.dart';
import 'push.dart';
import 'ui/events/events_controller.dart';
import 'ui/home/home_controller.dart';
import 'ui/in_app/in_app_controller.dart';
import 'ui/links/links_controller.dart';

const pluginVersion = '3.1.1';
const androidPackage = 'io.grovs.example';

class PanelState {
  const PanelState({this.open = false, this.entryId});

  final bool open;
  final int? entryId;
}

/// App-wide objects, created once by [AppGraph.init].
class AppGraph {
  AppGraph._();

  static late SettingsStore store;
  static late TestLog log;
  static late TestRunner runner;
  static NativeConfig config = NativeConfig.unknown;
  static LinksController? _links;
  static EventsController? _events;
  static InAppController? _inApp;
  static HomeController? _home;

  static LinksController get links => _links!;
  static EventsController get events => _events!;
  static InAppController get inApp => _inApp!;
  static HomeController get home => _home!;

  static final pushToken = ValueNotifier<String?>(null);
  static final sdkEnabled = ValueNotifier<bool>(true);
  static final panel = ValueNotifier<PanelState>(const PanelState());

  static final _subscriptions = <StreamSubscription<Object?>>[];

  static String get _apiKeyLocation =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? 'GrovsApiKey in Info.plist'
      : 'grovs_api_key in AndroidManifest.xml';

  static Future<void> init({String? deviceName}) async {
    _cancelSubscriptions();
    store = await SettingsStore.load(
      deviceName: deviceName ?? await _deviceName(),
    );
    log = TestLog(history: store.linkHistory);
    runner = TestRunner(log);
    _subscribe();
    config = await NativeConfig.read();
    sdkEnabled.value = config.startEnabled;
    await _applySavedSettings();
    final configured = config.apiKey.isNotEmpty;
    log.add(
      LogType.sdk,
      configured ? LogState.ok : LogState.warning,
      configured ? 'SDK configured' : 'SDK not configured',
      detail: configured
          ? '${config.useTestEnvironment ? 'test' : 'prod'} · natively'
          : 'Set the API key: $_apiKeyLocation',
      code: callCode('configure', [
        ('apiKey', middleEllipsis(config.apiKey)),
        ('useTestEnvironment', config.useTestEnvironment),
        ('baseURL', config.baseUrl),
        ('clipboardDomains', config.clipboardDomains),
        ('enabled', config.startEnabled),
      ]),
    );
    _links?.dispose();
    _links = LinksController();
    _events?.dispose();
    _events = EventsController();
    _inApp?.dispose();
    _inApp = InAppController();
    _home?.dispose();
    _home = HomeController();
    unawaited(Push.start());
  }

  static void rerun(TestAction action) => unawaited(runner.run(action));

  static void openPanel([int? entryId]) {
    panel.value = PanelState(open: true, entryId: entryId);
    log.markSeen();
  }

  /// Errors that arrived while the panel was open have been seen.
  static void closePanel() {
    panel.value = const PanelState();
    log.markSeen();
  }

  @visibleForTesting
  static void reset() {
    _cancelSubscriptions();
    _links?.dispose();
    _links = null;
    _events?.dispose();
    _events = null;
    _inApp?.dispose();
    _inApp = null;
    _home?.dispose();
    _home = null;
    Push.reset();
    config = NativeConfig.unknown;
    pushToken.value = null;
    sdkEnabled.value = true;
    panel.value = const PanelState();
  }

  static void _cancelSubscriptions() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _subscriptions.clear();
  }

  static Future<String> _deviceName() async {
    try {
      final info = DeviceInfoPlugin();
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => await info.androidInfo.then(
          (d) => '@${d.manufacturer} ${d.model}',
        ),
        TargetPlatform.iOS => await info.iosInfo.then((d) => '@${d.name}'),
        _ => '@device',
      };
    } catch (_) {
      return '@device';
    }
  }

  static Future<void> _applySavedSettings() async {
    final grovs = Grovs();
    final identity = store.identity;
    final attributes = toValueMap(identity.attributes);
    final tags = store.globalTags.isEmpty ? null : store.globalTags;
    final aliases = toAliasMap(store.screenAliases);
    final excluded = store.excludedScreens;
    final inAppDebug = store.inAppDebug;
    final level = store.debugLevel;

    await _apply(
      LogType.sdk,
      'Debug level $level',
      callCode('setDebugLevel', [('level', level)]),
      () => grovs.setDebugLevel(level),
    );
    final identifier = identity.identifier;
    if (identifier != null) {
      await _apply(
        LogType.sdk,
        'User identifier set',
        callCode('setUserIdentifier', [('identifier', identifier)]),
        () => grovs.setUserIdentifier(identifier),
      );
    }
    await _apply(
      LogType.sdk,
      'User attributes set',
      callCode('setUserAttributes', [('attributes', attributes)]),
      () => grovs.setUserAttributes(attributes),
    );
    await _apply(
      LogType.sdk,
      'Global tags set',
      callCode('setGlobalTags', [('tags', tags)]),
      () => grovs.setGlobalTags(tags),
    );
    await _apply(
      LogType.sdk,
      'Screen aliases set',
      callCode('setScreenAliases', [('aliases', aliases)]),
      () => grovs.setScreenAliases(aliases),
    );
    await _apply(
      LogType.inApp,
      'Excluded screens set',
      callCode('setInAppExcludedScreens', [('screens', excluded)]),
      () => grovs.setInAppExcludedScreens(excluded),
    );
    await _apply(
      LogType.inApp,
      'Debug logging ${inAppDebug ? 'on' : 'off'}',
      callCode('setInAppDebugLogging', [('enabled', inAppDebug)]),
      () => grovs.setInAppDebugLogging(inAppDebug),
    );
  }

  /// The runner turns a thrown error into an error entry, so later calls still run.
  static Future<void> _apply(
    LogType type,
    String title,
    String code,
    Future<void> Function() call,
  ) => runner.run(
    TestAction(type, title, code, () async {
      await call();
      return const ActionResult(LogState.ok, 'Restored from saved settings');
    }, repeatable: false),
  );

  static void _subscribe() {
    final grovs = Grovs();
    _subscriptions.addAll([
      grovs.onDeeplinkReceived.listen(
        (d) => log.recordLinkOpen(d.link, d.data, d.tracking?.toMap()),
        onError: _logStreamError,
      ),
      grovs.onInAppMessage.listen(_logInApp, onError: _logStreamError),
      grovs.onError.listen(
        (e) => log.add(
          LogType.sdk,
          LogState.error,
          e.code.nativeName,
          detail: e.message,
        ),
        onError: _logStreamError,
      ),
    ]);
  }

  static void _logStreamError(Object error) => log.add(
    LogType.sdk,
    LogState.error,
    'SDK stream failed',
    detail: '$error',
  );

  static void _logInApp(InAppMessageEvent event) {
    void add(LogState state, String title, String detail, String code) =>
        log.add(LogType.inApp, state, title, detail: detail, code: code);

    switch (event) {
      case InAppMessageShown(:final campaignId):
        add(
          LogState.ok,
          'Message $campaignId shown',
          '',
          callCode('onInAppMessageShown', [('campaignId', campaignId)]),
        );
      case InAppMessageClicked(
        :final campaignId,
        :final buttonId,
        :final payload,
      ):
        add(
          LogState.ok,
          'Clicked ${buttonId ?? 'message'}',
          [campaignId, payload?.keys.join(', ')].nonNulls.join(' · '),
          callCode('onInAppMessageClicked', [
            ('campaignId', campaignId),
            ('buttonId', buttonId),
            ('payload', payload),
          ]),
        );
      case InAppMessageDismissed(:final campaignId, :final reason):
        add(
          LogState.neutral,
          'Dismissed $campaignId',
          reason.name,
          callCode('onInAppMessageDismissed', [
            ('campaignId', campaignId),
            ('reason', reason.name),
          ]),
        );
      case InAppMessageAnswered(
        :final campaignId,
        :final value,
        :final comment,
      ):
        add(
          LogState.ok,
          'Answered $campaignId',
          ['$value', comment].nonNulls.join(' · '),
          callCode('onInAppMessageAnswered', [
            ('campaignId', campaignId),
            ('value', value),
            ('comment', comment),
          ]),
        );
      case InAppMessageFailed(:final campaignId, :final message):
        add(
          LogState.error,
          campaignId == null ? 'Message failed' : 'Message $campaignId failed',
          message,
          callCode('onInAppMessageFailed', [
            ('campaignId', campaignId),
            ('message', message),
          ]),
        );
    }
  }
}
