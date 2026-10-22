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

  group('GrovsLinkDetails.fromMap', () {
    Map<Object?, Object?> full() => <Object?, Object?>{
          'id': 12,
          'name': 'Spring',
          'path': 'abc123',
          'title': 'Sale',
          'subtitle': 'Up to 50%',
          'image': 'https://cdn.grovs.io/i.png',
          'access_path': 'https://app.sqd.link/abc123',
          'active': true,
          'sdk_generated': true,
          'data': <Object?, Object?>{
            'product': <Object?, Object?>{'id': 'p1'},
            'list': [1, 2],
          },
          'tags': ['a', 'b'],
          'updated_at': '2026-10-01T10:00:00.000Z',
          'show_preview_ios': false,
          'show_preview_android': true,
          'generated_from_platform': 'ios',
          'ads_platform': null,
          'campaign_id': 7,
          'visitor_id': 99,
          'tracking_source': 'email',
          'tracking_medium': 'news',
          'tracking_campaign': 'spring',
          'ios_custom_redirect': <Object?, Object?>{
            'url': 'https://x.io/ios',
            'open_app_if_installed': false,
          },
          'android_custom_redirect': null,
          'desktop_custom_redirect': <Object?, Object?>{'url': 'https://x.io/d'},
        };

    test('parses every typed field', () {
      final link = GrovsLinkDetails.fromMap(full());

      expect(link.id, 12);
      expect(link.name, 'Spring');
      expect(link.path, 'abc123');
      expect(link.title, 'Sale');
      expect(link.subtitle, 'Up to 50%');
      expect(link.image, 'https://cdn.grovs.io/i.png');
      expect(link.accessPath, 'https://app.sqd.link/abc123');
      expect(link.active, isTrue);
      expect(link.sdkGenerated, isTrue);
      expect(link.data, {
        'product': {'id': 'p1'},
        'list': [1, 2],
      });
      expect(link.tags, ['a', 'b']);
      expect(link.updatedAt, DateTime.utc(2026, 10, 1, 10));
      expect(link.showPreviewIos, isFalse);
      expect(link.showPreviewAndroid, isTrue);
      expect(link.generatedFromPlatform, 'ios');
      expect(link.adsPlatform, isNull);
      expect(link.campaignId, 7);
      expect(link.tracking!.utmSource, 'email');
      expect(link.tracking!.utmMedium, 'news');
      expect(link.tracking!.utmCampaign, 'spring');
      expect(link.customRedirects!.ios!.url, 'https://x.io/ios');
      expect(link.customRedirects!.ios!.openAppIfInstalled, isFalse);
      expect(link.customRedirects!.android, isNull);
      expect(link.customRedirects!.desktop!.url, 'https://x.io/d');
      expect(link.customRedirects!.desktop!.openAppIfInstalled, isTrue);
    });

    test('nested maps become Map<String, dynamic>', () {
      final link = GrovsLinkDetails.fromMap(full());

      expect(link.data!['product'], isA<Map<String, dynamic>>());
      expect(link.data!['product']['id'], 'p1');
      expect(link.raw['data'], isA<Map<String, dynamic>>());
      expect(link.raw['visitor_id'], 99);
    });

    test('whole doubles become int for id and campaignId', () {
      final link = GrovsLinkDetails.fromMap({
        ...full(),
        'id': 12.0,
        'campaign_id': 7.0,
      });

      expect(link.id, isA<int>());
      expect(link.id, 12);
      expect(link.campaignId, isA<int>());
      expect(link.campaignId, 7);
    });

    test('wrong types become null without throwing', () {
      final link = GrovsLinkDetails.fromMap({
        ...full(),
        'data': 'text',
        'image': 5,
        'tags': ['a', null, 3],
        'updated_at': 'nope',
        'active': 'yes',
        'id': 'x',
      });

      expect(link.data, isNull);
      expect(link.image, isNull);
      expect(link.tags, ['a']);
      expect(link.updatedAt, isNull);
      expect(link.active, isNull);
      expect(link.id, isNull);
      expect(link.raw['data'], 'text');
    });

    test('redirect without a string url is no redirect', () {
      final link = GrovsLinkDetails.fromMap({
        'ios_custom_redirect': {'url': null},
        'android_custom_redirect': {'url': null},
        'desktop_custom_redirect': {'url': null},
      });

      expect(link.customRedirects, isNull);
    });

    test('no tracking keys gives null tracking', () {
      final link = GrovsLinkDetails.fromMap({});

      expect(link.tracking, isNull);
      expect(link.customRedirects, isNull);
      expect(link.raw, isEmpty);
    });
  });

  test('CustomLinkRedirect.fromMap needs a map with a string url', () {
    expect(CustomLinkRedirect.fromMap(null), isNull);
    expect(CustomLinkRedirect.fromMap('x'), isNull);
    expect(CustomLinkRedirect.fromMap({'open_app_if_installed': true}), isNull);
  });
}
