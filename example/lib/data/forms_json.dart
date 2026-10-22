import 'dart:convert';

import 'package:grovs_flutter_plugin/models/grovs_link.dart';

import 'forms.dart';
import 'key_value.dart';

Map<String, Object?>? _object(String? json) {
  if (json == null) return null;
  try {
    final decoded = jsonDecode(json);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String _string(Object? v, String fallback) => v is String ? v : fallback;

bool _bool(Object? v, bool fallback) => v is bool ? v : fallback;

int _int(Object? v, int fallback) => v is num ? v.toInt() : fallback;

List<String> _strings(Object? v) =>
    v is List ? [for (final s in v.whereType<String>()) s] : const [];

List<KeyValue> _keyValues(
  Map<String, Object?> o,
  String key,
  List<KeyValue> fallback,
) => o.containsKey(key) ? keyValuesFromStore(o[key]) : fallback;

E _enum<E extends Enum>(List<E> values, Object? name, E fallback) =>
    values.where((e) => e.name == name).firstOrNull ?? fallback;

Map<String, Object?> _redirectToJson(Redirect r) => {
  'url': r.url,
  'open': r.openAppIfInstalled,
};

Redirect _redirect(Object? v, Redirect fallback) => v is Map
    ? Redirect(
        _string(v['url'], fallback.url),
        _bool(v['open'], fallback.openAppIfInstalled),
      )
    : fallback;

String encodeStrings(List<String> list) => jsonEncode(list);

List<String> decodeStrings(String? json) {
  if (json == null) return const [];
  try {
    return _strings(jsonDecode(json));
  } on FormatException {
    return const [];
  }
}

String encodeKeyValues(List<KeyValue> list) =>
    jsonEncode(keyValuesToStore(list));

/// Null when nothing valid is stored, so callers can apply their own default.
List<KeyValue>? decodeKeyValues(String? json) {
  if (json == null) return null;
  try {
    final decoded = jsonDecode(json);
    return decoded is List ? keyValuesFromStore(decoded) : null;
  } on FormatException {
    return null;
  }
}

String encodeLinkForm(LinkForm f) => jsonEncode({
  'title': f.title,
  'subtitle': f.subtitle,
  'data': keyValuesToStore(f.data),
  'imageUrl': f.imageUrl,
  'tags': f.tags,
  'utmOn': f.utmOn,
  'utmSource': f.utmSource,
  'utmMedium': f.utmMedium,
  'utmCampaign': f.utmCampaign,
  'redirectsOn': f.redirectsOn,
  'android': _redirectToJson(f.android),
  'ios': _redirectToJson(f.ios),
  'desktop': _redirectToJson(f.desktop),
  'previewAndroid': f.previewAndroid.name,
  'previewIos': f.previewIos.name,
  'clipboardAndroid': f.clipboardAndroid.name,
  'clipboardIos': f.clipboardIos.name,
});

LinkForm decodeLinkForm(String? json) {
  final o = _object(json);
  if (o == null) return const LinkForm();
  const d = LinkForm();
  return LinkForm(
    title: _string(o['title'], d.title),
    subtitle: _string(o['subtitle'], d.subtitle),
    data: _keyValues(o, 'data', d.data),
    imageUrl: _string(o['imageUrl'], d.imageUrl),
    tags: _strings(o['tags']),
    utmOn: _bool(o['utmOn'], d.utmOn),
    utmSource: _string(o['utmSource'], d.utmSource),
    utmMedium: _string(o['utmMedium'], d.utmMedium),
    utmCampaign: _string(o['utmCampaign'], d.utmCampaign),
    redirectsOn: _bool(o['redirectsOn'], d.redirectsOn),
    android: _redirect(o['android'], d.android),
    ios: _redirect(o['ios'], d.ios),
    desktop: _redirect(o['desktop'], d.desktop),
    previewAndroid: _enum(
      TriState.values,
      o['previewAndroid'],
      d.previewAndroid,
    ),
    previewIos: _enum(TriState.values, o['previewIos'], d.previewIos),
    clipboardAndroid: _enum(
      TriState.values,
      o['clipboardAndroid'],
      d.clipboardAndroid,
    ),
    clipboardIos: _enum(TriState.values, o['clipboardIos'], d.clipboardIos),
  );
}

String encodeEventForm(EventForm f) => jsonEncode({
  'name': f.name,
  'properties': keyValuesToStore(f.properties),
  'tags': f.tags,
});

EventForm decodeEventForm(String? json) {
  final o = _object(json);
  if (o == null) return const EventForm();
  const d = EventForm();
  return EventForm(
    name: _string(o['name'], d.name),
    properties: _keyValues(o, 'properties', d.properties),
    tags: _strings(o['tags']),
  );
}

String encodeScreenForm(ScreenForm f) =>
    jsonEncode({'name': f.name, 'properties': keyValuesToStore(f.properties)});

ScreenForm decodeScreenForm(String? json) {
  final o = _object(json);
  if (o == null) return const ScreenForm();
  const d = ScreenForm();
  return ScreenForm(
    name: _string(o['name'], d.name),
    properties: _keyValues(o, 'properties', d.properties),
  );
}

String encodePurchaseForm(PurchaseForm f) => jsonEncode({
  'type': f.type.name,
  'amount': f.amount,
  'currency': f.currency,
  'productId': f.productId,
  'startDaysAgo': f.startDaysAgo,
  'storeId': f.storeId,
});

PurchaseForm decodePurchaseForm(String? json) {
  final o = _object(json);
  if (o == null) return const PurchaseForm();
  const d = PurchaseForm();
  return PurchaseForm(
    type: _enum(TransactionType.values, o['type'], d.type),
    amount: _string(o['amount'], d.amount),
    currency: _string(o['currency'], d.currency),
    productId: _string(o['productId'], d.productId),
    startDaysAgo: _int(o['startDaysAgo'], d.startDaysAgo),
    storeId: _string(o['storeId'], d.storeId),
  );
}

String encodeIdentity(Identity identity) => jsonEncode({
  'identifier': identity.identifier,
  'attributes': keyValuesToStore(identity.attributes),
});

Identity decodeIdentity(String? json, Identity fallback) {
  final o = _object(json);
  if (o == null) return fallback;
  return Identity(
    identifier: o['identifier'] is String ? o['identifier'] as String : null,
    attributes: _keyValues(o, 'attributes', fallback.attributes),
  );
}
