import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

void main() {
  for (final copyToClipboard in <bool?>[true, false, null]) {
    test('link parameters preserve clipboard value $copyToClipboard', () {
      final params = GenerateLinkParams(
        title: 'Product',
        subtitle: 'Details',
        imageURL: 'https://example.com/image.png',
        data: {'productId': '123'},
        tags: ['sale'],
        customRedirects: CustomRedirects(
          ios: CustomLinkRedirect(url: 'https://example.com/ios'),
          android: CustomLinkRedirect(
            url: 'https://example.com/android',
            openAppIfInstalled: false,
          ),
        ),
        showPreviewIos: true,
        showPreviewAndroid: false,
        copyToClipboardIos: copyToClipboard,
        copyToClipboardAndroid: copyToClipboard,
        tracking: TrackingParams(
          utmCampaign: 'summer',
          utmSource: 'email',
          utmMedium: 'newsletter',
        ),
      );

      expect(params.copyToClipboardIos, copyToClipboard);
      expect(params.copyToClipboardAndroid, copyToClipboard);
      expect(params.toMap(), {
        'title': 'Product',
        'subtitle': 'Details',
        'imageURL': 'https://example.com/image.png',
        'data': {'productId': '123'},
        'tags': ['sale'],
        'customRedirects': {
          'ios': {'url': 'https://example.com/ios', 'openAppIfInstalled': true},
          'android': {
            'url': 'https://example.com/android',
            'openAppIfInstalled': false,
          },
          'desktop': null,
        },
        'showPreviewIos': true,
        'showPreviewAndroid': false,
        'copyToClipboardIos': copyToClipboard,
        'copyToClipboardAndroid': copyToClipboard,
        'tracking': {
          'utm_campaign': 'summer',
          'utm_source': 'email',
          'utm_medium': 'newsletter',
        },
      });
    });
  }

  test('clipboard options default to null and remain in the map', () {
    final params = GenerateLinkParams(title: 'Product');

    expect(params.copyToClipboardIos, isNull);
    expect(params.copyToClipboardAndroid, isNull);
    expect(params.toMap(), containsPair('copyToClipboardIos', null));
    expect(params.toMap(), containsPair('copyToClipboardAndroid', null));
  });

  final nativeCodes = {
    GrovsErrorCode.authenticationFailed: 'authentication_failed',
    GrovsErrorCode.networkRequestFailed: 'network_request_failed',
    GrovsErrorCode.eventDispatchFailed: 'event_dispatch_failed',
    GrovsErrorCode.linkGenerationFailed: 'link_generation_failed',
  };

  for (final entry in nativeCodes.entries) {
    test('decodes ${entry.value} and preserves its message', () {
      expect(entry.key.nativeName, entry.value);
      expect(GrovsErrorCode.fromNativeName(entry.value), entry.key);
      final error = GrovsError.fromMap({
        'code': entry.value,
        'message': 'Native failure',
      });

      expect(error?.code, entry.key);
      expect(error?.message, 'Native failure');
    });
  }

  test('unknown or missing error codes are ignored', () {
    expect(GrovsErrorCode.fromNativeName('future_error'), isNull);
    expect(GrovsErrorCode.fromNativeName(null), isNull);
    expect(GrovsError.fromMap({'code': 'future_error'}), isNull);
    expect(GrovsError.fromMap({}), isNull);
  });

  test('missing error message defaults to empty', () {
    final error = GrovsError.fromMap({'code': 'authentication_failed'});

    expect(error?.code, GrovsErrorCode.authenticationFailed);
    expect(error?.message, '');
  });

  test('error string includes its code and message', () {
    final error = GrovsError(
      code: GrovsErrorCode.networkRequestFailed,
      message: 'Request timed out',
    );

    expect(error.toString(), contains('network_request_failed'));
    expect(error.toString(), contains('Request timed out'));
  });
}
