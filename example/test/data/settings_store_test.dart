import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/data/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults on first launch', () async {
    final store = await SettingsStore.load(deviceName: 'Pixel 8');
    expect(store.identity.identifier, 'Pixel 8');
    expect(store.excludedScreens, ['ExcludedScreen']);
    expect(store.screenAliases.single.key, '/');
    expect(store.inAppDebug, isTrue);
    expect(store.triggerEvent, 'demo_tapped');
  });

  test('values survive a reload', () async {
    final store = await SettingsStore.load(deviceName: 'x');
    store.globalTags = ['beta'];
    store.excludedScreens = [];
    final again = await SettingsStore.load(deviceName: 'x');
    expect(again.globalTags, ['beta']);
    expect(again.excludedScreens, isEmpty);
  });

  test('recent values: newest first, unique, max 5', () async {
    final store = await SettingsStore.load(deviceName: 'x');
    for (final v in ['a', 'b', 'a', 'c', 'd', 'e', 'f']) {
      store.remember('events', v);
    }
    expect(store.recent('events'), ['f', 'e', 'd', 'c', 'a']);
  });
}
