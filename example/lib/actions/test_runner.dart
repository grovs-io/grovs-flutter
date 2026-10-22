import 'log.dart';
import 'test_log.dart';

class RunOutcome {
  const RunOutcome(this.result, this.entry, this.elapsed, [this.error]);

  final ActionResult result;
  final LogEntry entry;
  final Duration elapsed;
  final Object? error;
}

class TestRunner {
  TestRunner(this._log, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TestLog _log;
  final DateTime Function() _clock;

  Future<RunOutcome> run(TestAction action) async {
    final start = _clock();
    Object? error;
    ActionResult result;
    try {
      result = await action.run();
    } catch (e) {
      error = e;
      result = ActionResult(
        LogState.error,
        _message(e),
        code: '${action.code}\n\n$e',
      );
    }
    final elapsed = _clock().difference(start);
    final detail = result.state == LogState.error
        ? result.detail
        : '${result.detail} · ${elapsed.inMilliseconds} ms';
    final entry = _log.add(
      action.type,
      result.state,
      action.title,
      detail: detail,
      code: result.code ?? action.code,
      action: action,
    );
    return RunOutcome(result, entry, elapsed, error);
  }

  String _message(Object e) {
    final text = e.toString();
    return text.isEmpty ? e.runtimeType.toString() : text;
  }
}
