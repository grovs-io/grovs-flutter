String middleEllipsis(String text, {int keep = 5}) {
  if (text.length <= keep * 2 + 1) return text;
  return '${text.substring(0, keep)}…${text.substring(text.length - keep)}';
}

String formatClock(DateTime t, {bool seconds = false}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final base = '${two(t.hour)}:${two(t.minute)}';
  return seconds ? '$base:${two(t.second)}' : base;
}

String relativeTime(Duration elapsed) {
  final minutes = elapsed.inMinutes;
  final hours = elapsed.inHours;
  final days = elapsed.inDays;
  if (minutes < 1) return 'just now';
  if (hours < 1) return '$minutes min ago';
  if (days < 1) return '$hours h ago';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}
