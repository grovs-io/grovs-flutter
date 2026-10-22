import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/export_log.dart';
import 'package:grovs_example/actions/log.dart';
import 'package:grovs_example/actions/test_log.dart';

void main() {
  test('header then one block per entry, blank parts skipped', () {
    final log = TestLog(clock: () => DateTime(2026, 1, 1, 10, 0, 0))
      ..add(LogType.event, LogState.ok, 'track a', detail: 'sent', code: 'track()');
    expect(exportLog(log.entries, 'H', (_) => '10:00:00'), 'H\n\n10:00:00 EVENT ok track a\nsent\ntrack()');
  });

  test('hidden values are shortened', () {
    final log = TestLog(clock: () => DateTime(2026, 1, 1))
      ..add(LogType.push, LogState.ok, 'token', code: 'setPushToken(token: "abcdefghijklmnop")');
    final text = exportLog(log.entries, 'H', (_) => 't', hide: ['abcdefghijklmnop']);
    expect(text, contains('setPushToken(token: "abcde…lmnop")'));
    expect(text, isNot(contains('abcdefghijklmnop')));
  });
}
