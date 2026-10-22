import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/log.dart';
import 'package:grovs_example/actions/test_log.dart';
import 'package:grovs_example/actions/test_runner.dart';

void main() {
  test('logs the result with elapsed time and keeps the action', () async {
    final log = TestLog();
    final action = TestAction(LogType.event, 'track a', 'track()', () async => const ActionResult(LogState.ok, 'sent'));
    final outcome = await TestRunner(log).run(action);
    expect(outcome.entry.detail, startsWith('sent · '));
    expect(outcome.entry.detail, endsWith(' ms'));
    expect(log.entries.single.action, same(action));
  });

  test('a throwing action becomes an error entry', () async {
    final log = TestLog();
    final action = TestAction(LogType.create, 'Generate link', 'generateLink()', () async => throw StateError('nope'));
    final outcome = await TestRunner(log).run(action);
    expect(outcome.result.state, LogState.error);
    expect(outcome.error, isA<StateError>());
    expect(log.entries.single.code, contains('Bad state: nope'));
  });

  test('running again uses the same values', () async {
    var calls = 0;
    final action = TestAction(LogType.event, 't', 'c', () async {
      calls++;
      return ActionResult(LogState.ok, 'call $calls');
    });
    final runner = TestRunner(TestLog());
    await runner.run(action);
    final again = await runner.run(action);
    expect(calls, 2);
    expect(again.entry.title, 't');
  });
}
