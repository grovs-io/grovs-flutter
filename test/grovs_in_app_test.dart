import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/models/grovs_in_app.dart';

void main() {
  test('maps every event type', () {
    expect(
      InAppMessageEvent.fromMap({'type': 'shown', 'campaignId': 'c1'}),
      isA<InAppMessageShown>().having((e) => e.campaignId, 'id', 'c1'),
    );
    final clicked = InAppMessageEvent.fromMap({
      'type': 'clicked',
      'campaignId': 'c1',
      'buttonId': 'b1',
      'payload': {
        'k': 1,
        'n': {'x': true},
      },
    }) as InAppMessageClicked;
    expect(clicked.buttonId, 'b1');
    expect(clicked.payload, {
      'k': 1,
      'n': {'x': true},
    });
    expect(
      (InAppMessageEvent.fromMap({
        'type': 'dismissed',
        'campaignId': 'c1',
        'reason': 'close_button',
      }) as InAppMessageDismissed)
          .reason,
      InAppDismissReason.closeButton,
    );
    final stars = InAppMessageEvent.fromMap({
      'type': 'answered',
      'campaignId': 'c1',
      'value': 4,
      'comment': 'ok',
    }) as InAppMessageAnswered;
    expect(stars.value, 4);
    expect(stars.comment, 'ok');
    expect(
      (InAppMessageEvent.fromMap({
        'type': 'answered',
        'campaignId': 'c1',
        'value': 'opt_a',
      }) as InAppMessageAnswered)
          .value,
      'opt_a',
    );
    final failed = InAppMessageEvent.fromMap({
      'type': 'failed',
      'message': 'no window',
    }) as InAppMessageFailed;
    expect(failed.campaignId, isNull);
    expect(failed.message, 'no window');
  });

  test('nested payload maps from the channel get string keys', () {
    final Map<dynamic, dynamic> raw = {
      'type': 'clicked',
      'campaignId': 'c1',
      'payload': <dynamic, dynamic>{
        'n': <dynamic, dynamic>{'x': 1},
        'l': [
          <dynamic, dynamic>{'y': 2},
        ],
      },
    };
    final clicked = InAppMessageEvent.fromMap(raw) as InAppMessageClicked;
    expect(clicked.payload!['n'], isA<Map<String, dynamic>>());
    expect((clicked.payload!['l'] as List).first, isA<Map<String, dynamic>>());
  });

  test('every reason string maps to its enum value', () {
    const reasons = {
      'close_button': InAppDismissReason.closeButton,
      'backdrop': InAppDismissReason.backdrop,
      'swipe': InAppDismissReason.swipe,
      'app': InAppDismissReason.app,
      'orientation': InAppDismissReason.orientation,
    };
    reasons.forEach((wire, expected) {
      final event = InAppMessageEvent.fromMap({
        'type': 'dismissed',
        'campaignId': 'c1',
        'reason': wire,
      }) as InAppMessageDismissed;
      expect(event.reason, expected);
    });
  });

  test('unknown reason maps to unknown', () {
    final event = InAppMessageEvent.fromMap({
      'type': 'dismissed',
      'campaignId': 'c1',
      'reason': 'later',
    }) as InAppMessageDismissed;
    expect(event.reason, InAppDismissReason.unknown);
  });

  test('unknown type, or a missing campaignId on shown, returns null', () {
    expect(InAppMessageEvent.fromMap({'type': 'opened'}), isNull);
    expect(InAppMessageEvent.fromMap({'type': 'shown'}), isNull);
  });

  test('clicked without buttonId or payload keeps both null', () {
    final clicked = InAppMessageEvent.fromMap({
      'type': 'clicked',
      'campaignId': 'c1',
    }) as InAppMessageClicked;
    expect(clicked.buttonId, isNull);
    expect(clicked.payload, isNull);
  });

  test('answered keeps an unexpected value type as-is without throwing', () {
    final answered = InAppMessageEvent.fromMap({
      'type': 'answered',
      'campaignId': 'c1',
      'value': 4.5,
    }) as InAppMessageAnswered;
    expect(answered.value, 4.5);
  });
}
