import 'package:flutter/foundation.dart';
import 'package:grovs_flutter_plugin/grovs.dart';

import '../data/forms.dart';
import '../data/key_value.dart';
import '../data/money.dart';
import 'call_code.dart';
import 'log.dart';

class EventActions {
  EventActions._();

  static TestAction track(EventForm form, {bool expectRejected = false}) {
    final name = form.name.trim();
    final properties = _orNull(toValueMap(form.properties));
    final tags = form.tags.isEmpty ? null : form.tags;
    final code = callCode('track', [
      ('name', name),
      ('properties', properties),
      ('tags', tags),
    ]);
    return TestAction(LogType.event, 'track $name', code, () async {
      await Grovs().track(name, properties: properties, tags: tags);
      if (expectRejected) {
        return const ActionResult(
          LogState.warning,
          'sent anyway, the SDK should reject it',
        );
      }
      return ActionResult(
        LogState.ok,
        tags == null ? 'sent' : 'tags ${tags.join(', ')}',
      );
    });
  }

  static TestAction screen(ScreenForm form) {
    final name = form.name.trim();
    final properties = _orNull(toValueMap(form.properties));
    final code = callCode('trackScreenView', [
      ('screenName', name),
      ('properties', properties),
    ]);
    return TestAction(LogType.screen, 'Screen $name', code, () async {
      await Grovs().trackScreenView(name, properties: properties);
      return const ActionResult(LogState.ok, 'sent');
    });
  }

  static TestAction? purchase(PurchaseForm form, DateTime now) {
    if (!form.isValid()) return null;
    final cents = parseAmountToCents(form.amount);
    if (cents == null) return null;
    final start = now.subtract(Duration(days: form.startDaysAgo));
    final code = callCode('logCustomPurchase', [
      ('type', form.type.name),
      ('priceInCents', cents),
      ('currency', form.currency),
      ('productId', form.productId),
      ('startDate', start),
    ]);
    return TestAction(LogType.purchase, form.label(), code, () async {
      await Grovs().logCustomPurchase(
        type: form.type,
        priceInCents: cents,
        currency: form.currency,
        productId: form.productId,
        startDate: start,
      );
      return ActionResult(LogState.ok, '$cents cents · ${form.productId}');
    });
  }

  /// Play purchase JSON on Android, App Store transaction id on iOS.
  static TestAction storePurchase(String id) {
    final title = defaultTargetPlatform == TargetPlatform.iOS
        ? 'App Store purchase'
        : 'Google Play purchase';
    return TestAction(
      LogType.purchase,
      title,
      callCode('logInAppPurchase', [('transactionId', id)]),
      () async {
        await Grovs().logInAppPurchase(id);
        return const ActionResult(LogState.ok, 'sent');
      },
    );
  }

  static TestAction globalTags(List<String> tags) {
    final value = tags.isEmpty ? null : tags;
    return TestAction(
      LogType.sdk,
      'Global tags set',
      callCode('setGlobalTags', [('tags', value)]),
      () async {
        await Grovs().setGlobalTags(value);
        return ActionResult(
          LogState.ok,
          tags.isEmpty ? 'cleared' : tags.join(', '),
        );
      },
      repeatable: false,
    );
  }

  static TestAction aliases(List<KeyValue> rows) {
    final map = toAliasMap(rows);
    return TestAction(
      LogType.sdk,
      'Screen aliases set',
      callCode('setScreenAliases', [('aliases', map)]),
      () async {
        await Grovs().setScreenAliases(map);
        return ActionResult(LogState.ok, '${map.length} aliases');
      },
      repeatable: false,
    );
  }

  static TestAction trigger(String name) {
    final trimmed = name.trim();
    return TestAction(
      LogType.event,
      'Trigger $trimmed',
      callCode('track', [('name', trimmed)]),
      () async {
        await Grovs().track(trimmed);
        return const ActionResult(LogState.ok, 'sent');
      },
    );
  }

  static Map<String, Object>? _orNull(Map<String, Object> map) =>
      map.isEmpty ? null : map;
}
