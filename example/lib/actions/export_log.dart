import '../data/strings.dart';
import 'log.dart';

/// Each value in [hide] is shortened, so a shared log does not leak it.
String exportLog(
  List<LogEntry> entries,
  String header,
  String Function(DateTime) formatTime, {
  Iterable<String> hide = const [],
}) {
  String shorten(String text) => hide.fold(
    text,
    (out, secret) => out.replaceAll(secret, middleEllipsis(secret)),
  );
  final blocks = entries.map((e) {
    final parts = [
      '${formatTime(e.time)} ${e.type.label} ${e.state.name} ${e.title}',
      shorten(e.detail),
      shorten(e.code),
    ];
    return parts.where((p) => p.trim().isNotEmpty).join('\n');
  });
  return '$header\n\n${blocks.join('\n\n')}';
}
