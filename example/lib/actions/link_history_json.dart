import 'dart:convert';

import 'log.dart';

String encodeLinkEntries(List<LogEntry> entries) => jsonEncode([
  for (final e in entries)
    {
      'time': e.time.millisecondsSinceEpoch,
      'title': e.title,
      'detail': e.detail,
      'code': e.code,
      'link': e.link,
    },
]);

List<LogEntry> decodeLinkEntries(String? json) {
  if (json == null) return const [];
  try {
    return [
      for (final o in jsonDecode(json) as List)
        LogEntry(
          id: 0,
          time: DateTime.fromMillisecondsSinceEpoch(o['time'] as int),
          type: LogType.link,
          state: LogState.ok,
          title: o['title'] as String,
          detail: o['detail'] as String,
          code: o['code'] as String,
          link: o['link'] as String?,
        ),
    ];
  } on Object {
    return const [];
  }
}
