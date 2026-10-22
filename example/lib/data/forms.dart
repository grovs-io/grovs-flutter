import 'package:flutter/foundation.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

import 'key_value.dart';
import 'money.dart';

enum TriState {
  byDefault('Default'),
  on('On'),
  off('Off');

  const TriState(this.label);

  final String label;

  bool? toBool() => switch (this) {
    byDefault => null,
    on => true,
    off => false,
  };
}

class Redirect {
  const Redirect([this.url = '', this.openAppIfInstalled = false]);

  final String url;
  final bool openAppIfInstalled;

  Redirect copyWith({String? url, bool? openAppIfInstalled}) =>
      Redirect(url ?? this.url, openAppIfInstalled ?? this.openAppIfInstalled);

  @override
  bool operator ==(Object other) =>
      other is Redirect &&
      other.url == url &&
      other.openAppIfInstalled == openAppIfInstalled;

  @override
  int get hashCode => Object.hash(url, openAppIfInstalled);
}

const sampleImage1 = 'https://picsum.photos/seed/grovs1/1200/630';
const sampleImage2 = 'https://picsum.photos/seed/grovs2/1200/630';
const sampleRedirects = [
  'https://www.youtube.com',
  'https://www.google.com',
  'https://grovs.io',
];

class LinkForm {
  const LinkForm({
    this.title = 'Test title',
    this.subtitle = 'Test subtitle',
    this.data = const [KeyValue(key: 'param1', raw: 'Test value')],
    this.imageUrl = '',
    this.tags = const [],
    this.utmOn = false,
    this.utmSource = 'test_source',
    this.utmMedium = 'test_medium',
    this.utmCampaign = 'test_campaign',
    this.redirectsOn = false,
    this.android = const Redirect('https://www.youtube.com'),
    this.ios = const Redirect('https://www.google.com'),
    this.desktop = const Redirect(),
    this.previewAndroid = TriState.byDefault,
    this.previewIos = TriState.byDefault,
    this.clipboardAndroid = TriState.byDefault,
    this.clipboardIos = TriState.byDefault,
  });

  final String title;
  final String subtitle;
  final List<KeyValue> data;
  final String imageUrl;
  final List<String> tags;
  final bool utmOn;
  final String utmSource;
  final String utmMedium;
  final String utmCampaign;
  final bool redirectsOn;
  final Redirect android;
  final Redirect ios;
  final Redirect desktop;
  final TriState previewAndroid;
  final TriState previewIos;
  final TriState clipboardAndroid;
  final TriState clipboardIos;

  LinkForm copyWith({
    String? title,
    String? subtitle,
    List<KeyValue>? data,
    String? imageUrl,
    List<String>? tags,
    bool? utmOn,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    bool? redirectsOn,
    Redirect? android,
    Redirect? ios,
    Redirect? desktop,
    TriState? previewAndroid,
    TriState? previewIos,
    TriState? clipboardAndroid,
    TriState? clipboardIos,
  }) => LinkForm(
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    data: data ?? this.data,
    imageUrl: imageUrl ?? this.imageUrl,
    tags: tags ?? this.tags,
    utmOn: utmOn ?? this.utmOn,
    utmSource: utmSource ?? this.utmSource,
    utmMedium: utmMedium ?? this.utmMedium,
    utmCampaign: utmCampaign ?? this.utmCampaign,
    redirectsOn: redirectsOn ?? this.redirectsOn,
    android: android ?? this.android,
    ios: ios ?? this.ios,
    desktop: desktop ?? this.desktop,
    previewAndroid: previewAndroid ?? this.previewAndroid,
    previewIos: previewIos ?? this.previewIos,
    clipboardAndroid: clipboardAndroid ?? this.clipboardAndroid,
    clipboardIos: clipboardIos ?? this.clipboardIos,
  );

  String moreSummary() => [
    utmOn ? 'UTM on' : 'UTM off',
    tags.isEmpty ? 'no tags' : '${tags.length} tags',
    imageUrl.trim().isEmpty ? 'no image' : 'image',
    redirectsOn ? 'redirects on' : 'no redirects',
  ].join(' · ');

  String overridesSummary() {
    final set = [
      previewAndroid,
      previewIos,
      clipboardAndroid,
      clipboardIos,
    ].where((t) => t != TriState.byDefault).length;
    return set == 0 ? 'all default' : '$set set';
  }

  @override
  bool operator ==(Object other) =>
      other is LinkForm &&
      other.title == title &&
      other.subtitle == subtitle &&
      listEquals(other.data, data) &&
      other.imageUrl == imageUrl &&
      listEquals(other.tags, tags) &&
      other.utmOn == utmOn &&
      other.utmSource == utmSource &&
      other.utmMedium == utmMedium &&
      other.utmCampaign == utmCampaign &&
      other.redirectsOn == redirectsOn &&
      other.android == android &&
      other.ios == ios &&
      other.desktop == desktop &&
      other.previewAndroid == previewAndroid &&
      other.previewIos == previewIos &&
      other.clipboardAndroid == clipboardAndroid &&
      other.clipboardIos == clipboardIos;

  @override
  int get hashCode => Object.hash(
    title,
    subtitle,
    Object.hashAll(data),
    imageUrl,
    Object.hashAll(tags),
    utmOn,
    utmSource,
    utmMedium,
    utmCampaign,
    redirectsOn,
    android,
    ios,
    desktop,
    previewAndroid,
    previewIos,
    clipboardAndroid,
    clipboardIos,
  );
}

class EventForm {
  const EventForm({
    this.name = 'demo_tapped',
    this.properties = const [],
    this.tags = const [],
  });

  final String name;
  final List<KeyValue> properties;
  final List<String> tags;

  EventForm copyWith({
    String? name,
    List<KeyValue>? properties,
    List<String>? tags,
  }) => EventForm(
    name: name ?? this.name,
    properties: properties ?? this.properties,
    tags: tags ?? this.tags,
  );

  @override
  bool operator ==(Object other) =>
      other is EventForm &&
      other.name == name &&
      listEquals(other.properties, properties) &&
      listEquals(other.tags, tags);

  @override
  int get hashCode =>
      Object.hash(name, Object.hashAll(properties), Object.hashAll(tags));
}

class ScreenForm {
  const ScreenForm({this.name = 'Checkout', this.properties = const []});

  final String name;
  final List<KeyValue> properties;

  ScreenForm copyWith({String? name, List<KeyValue>? properties}) => ScreenForm(
    name: name ?? this.name,
    properties: properties ?? this.properties,
  );

  @override
  bool operator ==(Object other) =>
      other is ScreenForm &&
      other.name == name &&
      listEquals(other.properties, properties);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(properties));
}

class PurchaseForm {
  const PurchaseForm({
    this.type = TransactionType.buy,
    this.amount = '4.99',
    this.currency = 'USD',
    this.productId = 'pro_monthly',
    this.startDaysAgo = 0,
    this.storeId = '',
  });

  final TransactionType type;
  final String amount;
  final String currency;
  final String productId;
  final int startDaysAgo;

  /// Play purchase JSON on Android, App Store transaction id on iOS.
  final String storeId;

  PurchaseForm copyWith({
    TransactionType? type,
    String? amount,
    String? currency,
    String? productId,
    int? startDaysAgo,
    String? storeId,
  }) => PurchaseForm(
    type: type ?? this.type,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    productId: productId ?? this.productId,
    startDaysAgo: startDaysAgo ?? this.startDaysAgo,
    storeId: storeId ?? this.storeId,
  );

  String label() {
    final cents = parseAmountToCents(amount);
    if (cents == null) return 'Log purchase';
    return 'Log ${currencySymbol(currency)}${formatCents(cents)} ${type.name}';
  }

  String fullLabel() => '${label()} · $currency · $productId';

  bool isValid() =>
      parseAmountToCents(amount) != null &&
      currency.trim().isNotEmpty &&
      productId.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is PurchaseForm &&
      other.type == type &&
      other.amount == amount &&
      other.currency == currency &&
      other.productId == productId &&
      other.startDaysAgo == startDaysAgo &&
      other.storeId == storeId;

  @override
  int get hashCode =>
      Object.hash(type, amount, currency, productId, startDaysAgo, storeId);
}

class Identity {
  const Identity({this.identifier, this.attributes = const []});

  final String? identifier;
  final List<KeyValue> attributes;

  Identity copyWith({
    String? identifier,
    List<KeyValue>? attributes,
    bool clearIdentifier = false,
  }) => Identity(
    identifier: clearIdentifier ? null : (identifier ?? this.identifier),
    attributes: attributes ?? this.attributes,
  );

  @override
  bool operator ==(Object other) =>
      other is Identity &&
      other.identifier == identifier &&
      listEquals(other.attributes, attributes);

  @override
  int get hashCode => Object.hash(identifier, Object.hashAll(attributes));
}

const defaultAttributes = [
  KeyValue(key: 'param1', raw: 'value1'),
  KeyValue(key: 'param2', raw: '123'),
  KeyValue(key: 'param3', raw: 'true'),
];
