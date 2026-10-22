/// Accepts a full link, host/path or only the path, and returns the last path segment.
String? extractLinkPath(String input) {
  final clean = input.trim().split('#').first.split('?').first;
  if (clean.isEmpty) return null;
  final schemeEnd = clean.indexOf('://');
  final afterScheme = schemeEnd < 0 ? clean : clean.substring(schemeEnd + 3);
  final hasHost = schemeEnd >= 0 || afterScheme.contains('/');
  final path = hasHost
      ? (afterScheme.contains('/') ? afterScheme.substring(afterScheme.indexOf('/') + 1) : '')
      : afterScheme;
  for (final segment in path.split('/').reversed) {
    if (segment.trim().isNotEmpty) return segment;
  }
  return null;
}

bool isWebUrl(String input) {
  final v = input.trim();
  final String rest;
  if (v.startsWith('https://')) {
    rest = v.substring('https://'.length);
  } else if (v.startsWith('http://')) {
    rest = v.substring('http://'.length);
  } else {
    return false;
  }
  return rest.split('/').first.trim().isNotEmpty;
}

String adbCommand(String link, String packageName) =>
    'adb shell am start -a android.intent.action.VIEW -d "$link" $packageName';

String simctlCommand(String link) => 'xcrun simctl openurl booted "$link"';

List<(String, String)> flatten(Map<String, Object?> map, [String prefix = '']) {
  return [
    for (final entry in map.entries)
      ..._flattenEntry(prefix.isEmpty ? entry.key : '$prefix.${entry.key}', entry.value),
  ];
}

List<(String, String)> _flattenEntry(String name, Object? value) {
  if (value is Map) return flatten(value.cast<String, Object?>(), name);
  if (value is List) return [(name, value.join(', '))];
  return [(name, '$value')];
}
