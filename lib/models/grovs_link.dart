/// Tracking parameters for UTM analytics
class TrackingParams {
  /// UTM campaign parameter
  final String? utmCampaign;

  /// UTM source parameter
  final String? utmSource;

  /// UTM medium parameter
  final String? utmMedium;

  TrackingParams({this.utmCampaign, this.utmSource, this.utmMedium});

  factory TrackingParams.fromMap(Map<String, dynamic> map) {
    return TrackingParams(
      utmCampaign: map['campaign'] as String?,
      utmSource: map['source'] as String?,
      utmMedium: map['medium'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'utm_campaign': utmCampaign,
      'utm_source': utmSource,
      'utm_medium': utmMedium,
    };
  }
}

/// Represents the details of a deeplink received from Grovs
class DeeplinkDetails {
  /// The deeplink URL
  final String? link;

  /// The payload data associated with the deeplink
  final Map<String, dynamic>? data;

  /// The tracking parameters associated with the deeplink
  final TrackingParams? tracking;

  DeeplinkDetails({this.link, this.data, this.tracking});

  factory DeeplinkDetails.fromMap(Map<dynamic, dynamic> map) {
    return DeeplinkDetails(
      link: map['link'] as String?,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      tracking: map['tracking'] != null
          ? TrackingParams.fromMap(Map<String, dynamic>.from(map['tracking']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'link': link, 'data': data, 'tracking': tracking?.toMap()};
  }
}

/// Details of a Grovs link, as returned by `Grovs().linkDetails`.
///
/// Fields whose value has an unexpected type are null. Every field the
/// backend sent is still available in [raw].
class GrovsLinkDetails {
  final int? id;
  final String? name;

  /// The last part of the link, for example `abc123`.
  final String? path;
  final String? title;
  final String? subtitle;

  /// URL of the link's preview image.
  final String? image;

  /// The full link URL.
  final String? accessPath;
  final bool? active;
  final bool? sdkGenerated;

  /// The payload data attached to the link, passed through as received.
  final Map<String, dynamic>? data;
  final List<String>? tags;
  final DateTime? updatedAt;
  final bool? showPreviewIos;
  final bool? showPreviewAndroid;
  final String? generatedFromPlatform;
  final String? adsPlatform;
  final int? campaignId;
  final TrackingParams? tracking;
  final CustomRedirects? customRedirects;

  /// Every field as received. Numbers can be doubles on Android and ints on
  /// iOS; the typed fields are the same on both platforms.
  final Map<String, dynamic> raw;

  GrovsLinkDetails({
    this.id,
    this.name,
    this.path,
    this.title,
    this.subtitle,
    this.image,
    this.accessPath,
    this.active,
    this.sdkGenerated,
    this.data,
    this.tags,
    this.updatedAt,
    this.showPreviewIos,
    this.showPreviewAndroid,
    this.generatedFromPlatform,
    this.adsPlatform,
    this.campaignId,
    this.tracking,
    this.customRedirects,
    this.raw = const {},
  });

  factory GrovsLinkDetails.fromMap(Map<dynamic, dynamic> map) {
    final raw = _stringKeyed(map);
    final source = _string(raw['tracking_source']);
    final medium = _string(raw['tracking_medium']);
    final campaign = _string(raw['tracking_campaign']);
    final ios = CustomLinkRedirect.fromMap(raw['ios_custom_redirect']);
    final android = CustomLinkRedirect.fromMap(raw['android_custom_redirect']);
    final desktop = CustomLinkRedirect.fromMap(raw['desktop_custom_redirect']);
    final tags = raw['tags'];
    final updatedAt = _string(raw['updated_at']);
    final data = raw['data'];

    return GrovsLinkDetails(
      id: _int(raw['id']),
      name: _string(raw['name']),
      path: _string(raw['path']),
      title: _string(raw['title']),
      subtitle: _string(raw['subtitle']),
      image: _string(raw['image']),
      accessPath: _string(raw['access_path']),
      active: _bool(raw['active']),
      sdkGenerated: _bool(raw['sdk_generated']),
      data: data is Map<String, dynamic> ? data : null,
      tags: tags is List ? tags.whereType<String>().toList() : null,
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
      showPreviewIos: _bool(raw['show_preview_ios']),
      showPreviewAndroid: _bool(raw['show_preview_android']),
      generatedFromPlatform: _string(raw['generated_from_platform']),
      adsPlatform: _string(raw['ads_platform']),
      campaignId: _int(raw['campaign_id']),
      tracking: source == null && medium == null && campaign == null
          ? null
          : TrackingParams(
              utmSource: source,
              utmMedium: medium,
              utmCampaign: campaign,
            ),
      customRedirects: ios == null && android == null && desktop == null
          ? null
          : CustomRedirects(ios: ios, android: android, desktop: desktop),
      raw: raw,
    );
  }
}

String? _string(Object? value) => value is String ? value : null;

bool? _bool(Object? value) => value is bool ? value : null;

int? _int(Object? value) => value is num ? value.toInt() : null;

/// Platform channels deliver nested maps as `Map<Object?, Object?>`.
Map<String, dynamic> _stringKeyed(Map<dynamic, dynamic> map) =>
    map.map((key, value) => MapEntry(key.toString(), _converted(value)));

Object? _converted(Object? value) {
  if (value is Map) return _stringKeyed(value);
  if (value is List) return value.map(_converted).toList();
  return value;
}

/// Custom link redirect configuration
class CustomLinkRedirect {
  /// The URL to redirect to
  final String url;

  /// Whether to open the app if installed (default: true)
  /// true: if the app is installed it will handle the link
  /// false: even if the app is installed, the link should be opened in the browser
  final bool openAppIfInstalled;

  CustomLinkRedirect({required this.url, this.openAppIfInstalled = true});

  /// Parses a backend redirect. Returns null unless [value] is a map with a
  /// string `url`.
  static CustomLinkRedirect? fromMap(Object? value) {
    if (value is! Map) return null;
    final url = value['url'];
    if (url is! String) return null;
    final openApp = value['open_app_if_installed'];
    return CustomLinkRedirect(
      url: url,
      openAppIfInstalled: openApp is bool ? openApp : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'url': url, 'openAppIfInstalled': openAppIfInstalled};
  }
}

/// Custom redirects for different platforms
class CustomRedirects {
  final CustomLinkRedirect? ios;
  final CustomLinkRedirect? android;
  final CustomLinkRedirect? desktop;

  CustomRedirects({this.ios, this.android, this.desktop});

  Map<String, dynamic> toMap() {
    return {
      'ios': ios?.toMap(),
      'android': android?.toMap(),
      'desktop': desktop?.toMap(),
    };
  }
}

/// Parameters for generating a Grovs link
class GenerateLinkParams {
  /// The title of the link
  final String title;

  /// The subtitle of the link
  final String? subtitle;

  /// URL to an image for the link preview
  final String? imageURL;

  /// Custom data to be passed with the link
  final Map<String, dynamic>? data;

  /// Tags for organizing links
  final List<String>? tags;

  /// Custom redirect URLs for different platforms
  final CustomRedirects? customRedirects;

  /// Whether to show preview on iOS
  final bool? showPreviewIos;

  /// Whether to show preview on Android
  final bool? showPreviewAndroid;

  /// Whether the iOS link preview copies the link to the clipboard.
  /// Null uses the project default.
  final bool? copyToClipboardIos;

  /// Whether the Android link preview copies the link to the clipboard.
  /// Null uses the project default.
  final bool? copyToClipboardAndroid;

  /// Tracking parameters for UTM analytics
  final TrackingParams? tracking;

  GenerateLinkParams({
    required this.title,
    this.subtitle,
    this.imageURL,
    this.data,
    this.tags,
    this.customRedirects,
    this.showPreviewIos,
    this.showPreviewAndroid,
    this.copyToClipboardIos,
    this.copyToClipboardAndroid,
    this.tracking,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageURL': imageURL,
      'data': data,
      'tags': tags,
      'customRedirects': customRedirects?.toMap(),
      'showPreviewIos': showPreviewIos,
      'showPreviewAndroid': showPreviewAndroid,
      'copyToClipboardIos': copyToClipboardIos,
      'copyToClipboardAndroid': copyToClipboardAndroid,
      'tracking': tracking?.toMap(),
    };
  }
}

/// Native SDK error categories reported through the error stream.
enum GrovsErrorCode {
  authenticationFailed('authentication_failed'),
  networkRequestFailed('network_request_failed'),
  eventDispatchFailed('event_dispatch_failed'),
  linkGenerationFailed('link_generation_failed');

  final String nativeName;

  const GrovsErrorCode(this.nativeName);

  /// Returns null for missing or unsupported native error codes.
  static GrovsErrorCode? fromNativeName(String? name) {
    for (final code in values) {
      if (code.nativeName == name) return code;
    }
    return null;
  }
}

/// An asynchronous error reported by the native SDK.
class GrovsError {
  final GrovsErrorCode code;
  final String message;

  const GrovsError({required this.code, required this.message});

  /// Returns null when the native error code is unsupported.
  static GrovsError? fromMap(Map<dynamic, dynamic> map) {
    final code = GrovsErrorCode.fromNativeName(map['code'] as String?);
    if (code == null) return null;
    return GrovsError(code: code, message: map['message'] as String? ?? '');
  }

  @override
  String toString() => 'GrovsError: $message (code: ${code.nativeName})';
}

/// Exception thrown by Grovs SDK
class GrovsException implements Exception {
  final String message;
  final String? code;

  GrovsException(this.message, {this.code});

  @override
  String toString() =>
      'GrovsException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Type of transaction for revenue tracking
enum TransactionType {
  /// A purchase transaction
  buy,

  /// A cancellation transaction
  cancel,

  /// A refund transaction
  refund,
}
