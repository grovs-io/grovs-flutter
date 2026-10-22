import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/data/event_rules.dart';
import 'package:grovs_example/data/link_tools.dart';
import 'package:grovs_example/data/money.dart';
import 'package:grovs_example/data/strings.dart';

void main() {
  group('extractLinkPath', () {
    test(
      'full link',
      () => expect(extractLinkPath('https://x.sqd.link/abc?u=1#f'), 'abc'),
    );
    test(
      'host and path',
      () => expect(extractLinkPath('x.sqd.link/abc/'), 'abc'),
    );
    test('path only', () => expect(extractLinkPath('abc'), 'abc'));
    test(
      'host only has no path',
      () => expect(extractLinkPath('https://x.sqd.link'), isNull),
    );
    test('blank', () => expect(extractLinkPath('  '), isNull));
  });

  test('isWebUrl needs scheme and host', () {
    expect(isWebUrl('https://a.b'), isTrue);
    expect(isWebUrl('http://a'), isTrue);
    expect(isWebUrl('https://'), isFalse);
    expect(isWebUrl('ftp://a'), isFalse);
  });

  test('adb and simctl commands', () {
    expect(
      adbCommand('https://l/a', 'io.grovs.example'),
      'adb shell am start -a android.intent.action.VIEW -d "https://l/a" io.grovs.example',
    );
    expect(
      simctlCommand('https://l/a'),
      'xcrun simctl openurl booted "https://l/a"',
    );
  });

  test('flatten nests with dots and joins lists', () {
    expect(
      flatten({
        'a': {'b': 1},
        'c': [1, 2],
      }),
      [('a.b', '1'), ('c', '1, 2')],
    );
  });

  group('parseAmountToCents', () {
    test('whole and decimals', () {
      expect(parseAmountToCents('4.99'), 499);
      expect(parseAmountToCents('4,9'), 490);
      expect(parseAmountToCents('12'), 1200);
    });
    test('rejects bad input', () {
      expect(parseAmountToCents('4.999'), isNull);
      expect(parseAmountToCents('-1'), isNull);
      expect(parseAmountToCents(''), isNull);
      expect(parseAmountToCents('99999999999'), isNull);
    });
  });

  test('formatCents', () => expect(formatCents(499), '4.99'));
  test('currencySymbol falls back to the code', () {
    expect(currencySymbol('USD'), '\$');
    expect(currencySymbol('CHF'), 'CHF ');
  });

  group('event rules', () {
    test(
      'blank name',
      () => expect(eventNameError(' '), 'Enter an event name'),
    );
    test(
      'reserved name',
      () =>
          expect(eventNameError('install'), '"install" is reserved by the SDK'),
    );
    test('valid name', () => expect(eventNameError('demo_tapped'), isNull));
    test('too many tags', () {
      expect(tagsError(List.generate(21, (i) => 't$i')), 'Up to 20 tags');
    });
    test('tag too long', () {
      expect(tagsError(['x' * 256]), 'Each tag can have up to 255 characters');
    });
  });

  test('middleEllipsis keeps both ends', () {
    expect(middleEllipsis('abcdefghijklmnop'), 'abcde…lmnop');
    expect(middleEllipsis('short'), 'short');
  });

  test('relativeTime', () {
    expect(relativeTime(const Duration(seconds: 30)), 'just now');
    expect(relativeTime(const Duration(minutes: 5)), '5 min ago');
    expect(relativeTime(const Duration(hours: 3)), '3 h ago');
    expect(relativeTime(const Duration(days: 1)), 'yesterday');
    expect(relativeTime(const Duration(days: 4)), '4 days ago');
  });
}
