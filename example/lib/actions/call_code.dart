/// Writes an SDK call the way it would look in code, for the log detail view.
String callCode(String name, [List<(String, Object?)> args = const []]) {
  if (args.isEmpty) return '$name()';
  final lines = args.map((a) => '  ${a.$1} = ${render(a.$2, 1)}').join(',\n');
  return '$name(\n$lines\n)';
}

String render(Object? value, [int depth = 0]) {
  switch (value) {
    case null:
      return 'null';
    case String():
      return '"$value"';
    case DateTime():
      return '"${_formatDate(value)}"';
    case Map():
      if (value.isEmpty) return '{}';
      final pad = '  ' * (depth + 1);
      final body = value.entries
          .map((e) => '$pad${e.key}: ${render(e.value, depth + 1)}')
          .join(',\n');
      return '{\n$body\n${'  ' * depth}}';
    case List():
      return '[${value.map((v) => render(v, depth)).join(', ')}]';
    default:
      return '$value';
  }
}

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
