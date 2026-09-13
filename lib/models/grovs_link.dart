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

/// Custom link redirect configuration
class CustomLinkRedirect {
  /// The URL to redirect to
  final String url;

  /// Whether to open the app if installed (default: true)
  /// true: if the app is installed it will handle the link
  /// false: even if the app is installed, the link should be opened in the browser
  final bool openAppIfInstalled;

  CustomLinkRedirect({required this.url, this.openAppIfInstalled = true});

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
