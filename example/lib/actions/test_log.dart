import 'package:flutter/foundation.dart';

import 'call_code.dart';
import 'log.dart';

abstract interface class LinkHistory {
  List<LogEntry> load();
  void save(List<LogEntry> entries);
}

class _NoHistory implements LinkHistory {
  const _NoHistory();
  @override
  List<LogEntry> load() => const [];
  @override
  void save(List<LogEntry> entries) {}
}

DateTime _nowInMilliseconds() =>
    DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);

class TestLog extends ChangeNotifier {
  TestLog({LinkHistory? history, DateTime Function()? clock})
    : _history = history ?? const _NoHistory(),
      _clock = clock ?? _nowInMilliseconds {
    _entries = [for (final e in _history.load()) e.withId(_nextId++)];
    _links = List.of(_entries);
  }

  static const maxEntries = 500;
  static const maxLinks = 50;

  final LinkHistory _history;
  final DateTime Function() _clock;
  int _nextId = 1;
  late List<LogEntry> _entries;
  late List<LogEntry> _links;
  bool _unseenError = false;

  List<LogEntry> get entries => List.unmodifiable(_entries);
  bool get unseenError => _unseenError;

  LogEntry add(
    LogType type,
    LogState state,
    String title, {
    String detail = '',
    String code = '',
    TestAction? action,
  }) {
    final entry = LogEntry(
      id: _nextId++,
      time: _clock(),
      type: type,
      state: state,
      title: title,
      detail: detail,
      code: code,
      action: action,
    );
    _prepend(entry);
    if (state == LogState.error) _unseenError = true;
    notifyListeners();
    return entry;
  }

  LogEntry recordLinkOpen(
    String? link,
    Map<String, dynamic>? data,
    Map<String, dynamic>? tracking,
  ) {
    final entry = LogEntry(
      id: _nextId++,
      time: _clock(),
      type: LogType.link,
      state: LogState.ok,
      title: 'Opened from link',
      detail: '${_linkPath(link)} · received',
      code: callCode('onDeeplinkReceived', [
        ('link', link),
        ('data', data),
        ('tracking', tracking),
      ]),
      link: link,
    );
    _prepend(entry);
    _links = [entry, ..._links].take(maxLinks).toList();
    _history.save(_links);
    notifyListeners();
    return entry;
  }

  void markSeen() {
    if (!_unseenError) return;
    _unseenError = false;
    notifyListeners();
  }

  void clear() {
    _entries = [];
    _links = [];
    _unseenError = false;
    _history.save(const []);
    notifyListeners();
  }

  void _prepend(LogEntry entry) {
    _entries = [entry, ..._entries].take(maxEntries).toList();
  }

  String _linkPath(String? link) {
    final last = link?.split('/').last ?? '';
    return last.isEmpty ? 'no link' : last;
  }
}
