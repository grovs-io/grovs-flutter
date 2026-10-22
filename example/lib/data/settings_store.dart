import 'package:shared_preferences/shared_preferences.dart';

import '../actions/log.dart';
import '../actions/link_history_json.dart';
import '../actions/test_log.dart';
import 'forms.dart';
import 'forms_json.dart';
import 'key_value.dart';

const recentEvents = 'events';
const recentScreens = 'screens';
const recentTriggers = 'triggers';

const _maxRecent = 5;

const _kLinkForm = 'link_form';
const _kEventForm = 'event_form';
const _kScreenForm = 'screen_form';
const _kPurchaseForm = 'purchase_form';
const _kIdentity = 'identity';
const _kGlobalTags = 'global_tags';
const _kAliases = 'screen_aliases';
const _kExcluded = 'excluded_screens';
const _kInAppDebug = 'in_app_debug';
const _kDebugLevel = 'debug_level';
const _kTrigger = 'trigger_event';
const _kLinks = 'link_history';

/// Settings are read once at startup so the getters stay synchronous. Setters write
/// to the cache immediately and persist in the background.
class SettingsStore {
  SettingsStore._(this._prefs, this._deviceName);

  static Future<SettingsStore> load({required String deviceName}) async =>
      SettingsStore._(await SharedPreferences.getInstance(), deviceName);

  final SharedPreferences _prefs;
  final String _deviceName;

  LinkForm get linkForm => decodeLinkForm(_prefs.getString(_kLinkForm));
  set linkForm(LinkForm v) => _put(_kLinkForm, encodeLinkForm(v));

  EventForm get eventForm => decodeEventForm(_prefs.getString(_kEventForm));
  set eventForm(EventForm v) => _put(_kEventForm, encodeEventForm(v));

  ScreenForm get screenForm => decodeScreenForm(_prefs.getString(_kScreenForm));
  set screenForm(ScreenForm v) => _put(_kScreenForm, encodeScreenForm(v));

  PurchaseForm get purchaseForm =>
      decodePurchaseForm(_prefs.getString(_kPurchaseForm));
  set purchaseForm(PurchaseForm v) =>
      _put(_kPurchaseForm, encodePurchaseForm(v));

  Identity get identity => decodeIdentity(
    _prefs.getString(_kIdentity),
    Identity(identifier: _deviceName, attributes: defaultAttributes),
  );
  set identity(Identity v) => _put(_kIdentity, encodeIdentity(v));

  List<String> get globalTags => decodeStrings(_prefs.getString(_kGlobalTags));
  set globalTags(List<String> v) => _put(_kGlobalTags, encodeStrings(v));

  List<KeyValue> get screenAliases =>
      decodeKeyValues(_prefs.getString(_kAliases)) ??
      const [KeyValue(key: '/', raw: 'Home', type: ValueType.text)];
  set screenAliases(List<KeyValue> v) => _put(_kAliases, encodeKeyValues(v));

  List<String> get excludedScreens {
    final stored = _prefs.getString(_kExcluded);
    return stored == null ? const ['ExcludedScreen'] : decodeStrings(stored);
  }

  set excludedScreens(List<String> v) => _put(_kExcluded, encodeStrings(v));

  bool get inAppDebug => _prefs.getBool(_kInAppDebug) ?? true;
  set inAppDebug(bool v) => _prefs.setBool(_kInAppDebug, v);

  String get debugLevel => _prefs.getString(_kDebugLevel) ?? 'info';
  set debugLevel(String v) => _put(_kDebugLevel, v);

  String get triggerEvent => _prefs.getString(_kTrigger) ?? 'demo_tapped';
  set triggerEvent(String v) => _put(_kTrigger, v);

  List<String> recent(String field) =>
      decodeStrings(_prefs.getString('recent_$field'));

  void remember(String field, String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    final updated = [
      v,
      ...recent(field).where((r) => r != v),
    ].take(_maxRecent).toList();
    _put('recent_$field', encodeStrings(updated));
  }

  /// The persisted link history. A separate object because [SettingsStore.load] would clash with [LinkHistory.load].
  LinkHistory get linkHistory => _StoredLinkHistory(this);

  List<LogEntry> _loadLinks() => decodeLinkEntries(_prefs.getString(_kLinks));

  void _saveLinks(List<LogEntry> entries) =>
      _put(_kLinks, encodeLinkEntries(entries));

  void _put(String key, String value) => _prefs.setString(key, value);
}

class _StoredLinkHistory implements LinkHistory {
  _StoredLinkHistory(this._store);

  final SettingsStore _store;

  @override
  List<LogEntry> load() => _store._loadLinks();

  @override
  void save(List<LogEntry> entries) => _store._saveLinks(entries);
}
