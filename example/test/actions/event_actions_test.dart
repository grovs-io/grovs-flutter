import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/event_actions.dart';
import 'package:grovs_example/actions/log.dart';
import 'package:grovs_example/data/forms.dart';
import 'package:grovs_example/data/key_value.dart';

import '../fake_grovs.dart';

void main() {
  late FakeGrovs grovs;
  setUp(() async => grovs = await FakeGrovs.install());
  tearDown(() => grovs.uninstall());

  test('track trims the name and drops empty properties and tags', () async {
    await EventActions.track(const EventForm(name: ' demo_tapped ')).run();
    final args = grovs.lastArgs('track');
    expect(args['name'], 'demo_tapped');
    expect(args['properties'], isNull);
    expect(args['tags'], isNull);
  });

  test('track sends typed properties and tags', () async {
    final result = await EventActions.track(
      const EventForm(
        properties: [KeyValue(key: 'level', raw: '3')],
        tags: ['a', 'b'],
      ),
    ).run();
    final args = grovs.lastArgs('track');
    expect(args['properties'], {'level': 3});
    expect(args['tags'], ['a', 'b']);
    expect(result.detail, 'tags a, b');
  });

  test('send anyway is a warning', () async {
    final result = await EventActions.track(
      const EventForm(name: 'install'),
      expectRejected: true,
    ).run();
    expect(result.state, LogState.warning);
  });

  test('screen sends the name and properties', () async {
    await EventActions.screen(
      const ScreenForm(
        name: ' Home ',
        properties: [KeyValue(key: 'a', raw: 'b')],
      ),
    ).run();
    final args = grovs.lastArgs('trackScreenView');
    expect(args['screenName'], 'Home');
    expect(args['properties'], {'a': 'b'});
  });

  test('purchase sends cents and a start date in the past', () async {
    final now = DateTime(2026, 10, 22, 12);
    await EventActions.purchase(
      const PurchaseForm(startDaysAgo: 1),
      now,
    )!.run();
    final args = grovs.lastArgs('logCustomPurchase');
    expect(args['type'], 'buy');
    expect(args['priceInCents'], 499);
    expect(args['currency'], 'USD');
    expect(args['productId'], 'pro_monthly');
    expect(
      args['startDate'],
      now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
    );
  });

  test('invalid purchase builds no action', () {
    expect(
      EventActions.purchase(const PurchaseForm(amount: ''), DateTime.now()),
      isNull,
    );
  });

  test('store purchase sends the id, titled by platform', () async {
    final action = EventActions.storePurchase('{"a":1}');
    expect(action.title, 'Google Play purchase');
    await action.run();
    expect(grovs.lastArgs('logInAppPurchase')['transactionId'], '{"a":1}');

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(EventActions.storePurchase('1').title, 'App Store purchase');
  });

  test('setters are not repeatable', () {
    expect(EventActions.globalTags(const []).repeatable, isFalse);
    expect(
      EventActions.aliases(const [KeyValue(key: '/', raw: 'Home')]).repeatable,
      isFalse,
    );
  });

  test('empty global tags clear them', () async {
    final result = await EventActions.globalTags(const []).run();
    expect(grovs.lastArgs('setGlobalTags')['tags'], isNull);
    expect(result.detail, 'cleared');
  });

  test('aliases are sent as a map', () async {
    await EventActions.aliases(const [KeyValue(key: '/', raw: 'Home')]).run();
    expect(grovs.lastArgs('setScreenAliases')['aliases'], {'/': 'Home'});
  });

  test('trigger tracks the trimmed name', () async {
    await EventActions.trigger(' go ').run();
    expect(grovs.lastArgs('track')['name'], 'go');
  });
}
