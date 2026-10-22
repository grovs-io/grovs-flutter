import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/log.dart';
import 'package:grovs_example/actions/test_log.dart';

class MemoryHistory implements LinkHistory {
  List<LogEntry> saved = [];
  @override
  List<LogEntry> load() => saved;
  @override
  void save(List<LogEntry> entries) => saved = entries;
}

void main() {
  test('newest first and capped at 500', () {
    final log = TestLog();
    for (var i = 0; i < 510; i++) {
      log.add(LogType.event, LogState.ok, 'e$i');
    }
    expect(log.entries.length, 500);
    expect(log.entries.first.title, 'e509');
  });

  test('an error marks unseen until markSeen', () {
    final log = TestLog();
    log.add(LogType.sdk, LogState.error, 'boom');
    expect(log.unseenError, isTrue);
    log.markSeen();
    expect(log.unseenError, isFalse);
  });

  test('link opens are saved to history, up to 50', () {
    final history = MemoryHistory();
    final log = TestLog(history: history);
    for (var i = 0; i < 55; i++) {
      log.recordLinkOpen('https://l/p$i', null, null);
    }
    log.add(LogType.event, LogState.ok, 'not a link');
    expect(history.saved.length, 50);
    expect(history.saved.every((e) => e.type == LogType.link), isTrue);
    expect(history.saved.first.detail, 'p54 · received');
  });

  test('link history keeps links pushed out of the log', () {
    final history = MemoryHistory();
    final log = TestLog(history: history)..recordLinkOpen('https://l/a', null, null);
    for (var i = 0; i < TestLog.maxEntries; i++) {
      log.add(LogType.event, LogState.ok, 'e$i');
    }
    log.recordLinkOpen('https://l/b', null, null);
    expect(history.saved.map((e) => e.link), ['https://l/b', 'https://l/a']);
  });

  test('history is loaded on start with fresh ids', () {
    final history = MemoryHistory();
    TestLog(history: history).recordLinkOpen('https://l/a', null, null);
    final reloaded = TestLog(history: history);
    expect(reloaded.entries.single.link, 'https://l/a');
    expect(reloaded.add(LogType.sdk, LogState.ok, 'x').id, isNot(reloaded.entries.last.id));
  });

  test('clear empties entries and history', () {
    final history = MemoryHistory();
    final log = TestLog(history: history)..recordLinkOpen('https://l/a', null, null);
    log.clear();
    expect(log.entries, isEmpty);
    expect(history.saved, isEmpty);
  });

  test('filters', () {
    final log = TestLog()
      ..add(LogType.create, LogState.ok, 'a')
      ..add(LogType.inApp, LogState.error, 'b');
    expect(log.entries.where(LogFilter.links.matches).single.title, 'a');
    expect(log.entries.where(LogFilter.errors.matches).single.title, 'b');
  });
}
