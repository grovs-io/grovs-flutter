import 'dart:convert';

enum ValueType {
  text('abc'),
  number('123'),
  boolean('y/n'),
  date('date');

  const ValueType(this.badge);

  final String badge;

  ValueType get next => values[(index + 1) % values.length];
}

/// A map entry as typed by the user. A null [type] means the type is detected from [raw].
class KeyValue {
  const KeyValue({required this.key, required this.raw, this.type});

  final String key;
  final String raw;
  final ValueType? type;

  ValueType get resolvedType => type ?? detectType(raw);

  Object value() => convert(raw, resolvedType);

  KeyValue copyWith({String? key, String? raw, ValueType? type, bool clearType = false}) =>
      KeyValue(
        key: key ?? this.key,
        raw: raw ?? this.raw,
        type: clearType ? null : (type ?? this.type),
      );

  @override
  bool operator ==(Object other) =>
      other is KeyValue && other.key == key && other.raw == raw && other.type == type;

  @override
  int get hashCode => Object.hash(key, raw, type);
}

final _number = RegExp(r'^-?(0|[1-9]\d*)(\.\d+)?$');
final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool _isValidDate(String v) {
  if (!_isoDate.hasMatch(v)) return false;
  final parsed = DateTime.tryParse(v);
  if (parsed == null) return false;
  final parts = v.split('-').map(int.parse).toList();
  return parsed.year == parts[0] && parsed.month == parts[1] && parsed.day == parts[2];
}

ValueType detectType(String raw) {
  final v = raw.trim();
  if (v.toLowerCase() == 'true' || v.toLowerCase() == 'false') return ValueType.boolean;
  if (_number.hasMatch(v)) return ValueType.number;
  if (_isValidDate(v)) return ValueType.date;
  return ValueType.text;
}

/// Dates stay ISO strings because the plugin channel only carries JSON-like values.
Object convert(String raw, ValueType type) {
  final v = raw.trim();
  switch (type) {
    case ValueType.text:
      return raw;
    case ValueType.number:
      final number = int.tryParse(v) ?? double.tryParse(v);
      return number != null && number.isFinite ? number : raw;
    case ValueType.boolean:
      return v.toLowerCase() == 'true';
    case ValueType.date:
      return _isValidDate(v) ? v : raw;
  }
}

Iterable<KeyValue> _named(List<KeyValue> rows) => rows.where((r) => r.key.trim().isNotEmpty);

Map<String, Object> toValueMap(List<KeyValue> rows) =>
    {for (final r in _named(rows)) r.key.trim(): r.value()};

/// Screen aliases are plain text, so the raw value is kept.
Map<String, String> toAliasMap(List<KeyValue> rows) =>
    {for (final r in _named(rows)) r.key.trim(): r.raw};

String summary(List<KeyValue> rows) => _named(rows).map((r) => r.key.trim()).join(', ');

String keyValuesToJson(List<KeyValue> rows) =>
    const JsonEncoder.withIndent('  ').convert(toValueMap(rows));

List<KeyValue> parseKeyValues(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) throw const FormatException('Not a JSON object');
  return [
    for (final entry in decoded.entries)
      KeyValue(
        key: entry.key as String,
        raw: entry.value == null ? '' : entry.value.toString(),
        type: switch (entry.value) {
          bool() => ValueType.boolean,
          num() => ValueType.number,
          _ => ValueType.text,
        },
      ),
  ];
}

List<Map<String, Object?>> keyValuesToStore(List<KeyValue> rows) =>
    [for (final r in rows) {'k': r.key, 'v': r.raw, 't': r.type?.name}];

List<KeyValue> keyValuesFromStore(Object? stored) {
  if (stored is! List) return const [];
  return [
    for (final item in stored.whereType<Map>())
      KeyValue(
        key: item['k']?.toString() ?? '',
        raw: item['v']?.toString() ?? '',
        type: ValueType.values.where((t) => t.name == item['t']).firstOrNull,
      ),
  ];
}
