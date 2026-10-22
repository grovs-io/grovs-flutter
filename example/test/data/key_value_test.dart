import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/data/key_value.dart';

void main() {
  group('detectType', () {
    test('booleans in any case', () {
      expect(detectType('true'), ValueType.boolean);
      expect(detectType('FALSE'), ValueType.boolean);
    });
    test('integers and decimals', () {
      expect(detectType('123'), ValueType.number);
      expect(detectType('-4.5'), ValueType.number);
      expect(detectType('0.5'), ValueType.number);
      expect(detectType('007'), ValueType.text);
    });
    test('valid ISO dates only', () {
      expect(detectType('2024-01-31'), ValueType.date);
      expect(detectType('2024-02-31'), ValueType.text);
    });
    test('anything else is text', () {
      expect(detectType('hello'), ValueType.text);
      expect(detectType('1.2.3'), ValueType.text);
    });
  });

  group('convert', () {
    test('number keeps ints as int and decimals as double', () {
      expect(convert('12', ValueType.number), 12);
      expect(convert('1.5', ValueType.number), 1.5);
    });
    test('number that does not parse stays text', () {
      expect(convert('abc', ValueType.number), 'abc');
    });
    test('boolean', () {
      expect(convert('True', ValueType.boolean), true);
      expect(convert('nope', ValueType.boolean), false);
    });
    test('text keeps the raw value untrimmed', () {
      expect(convert(' a ', ValueType.text), ' a ');
    });
  });

  test('an explicit type wins over detection', () {
    const kv = KeyValue(key: 'n', raw: '123', type: ValueType.text);
    expect(kv.value(), '123');
  });

  test('toValueMap skips blank keys and trims keys', () {
    final map = toValueMap(const [
      KeyValue(key: ' a ', raw: '1'),
      KeyValue(key: ' ', raw: 'x'),
    ]);
    expect(map, {'a': 1});
  });

  test('JSON round trip keeps types', () {
    final rows = parseKeyValues('{"s": "12", "n": 12, "b": true, "z": null}');
    expect(rows.map((r) => r.resolvedType).toList(),
        [ValueType.text, ValueType.number, ValueType.boolean, ValueType.text]);
    expect(rows.first.value(), '12');
    expect(rows.last.raw, '');
    expect(parseKeyValues(keyValuesToJson(rows)).map((r) => r.value()).toList(),
        rows.map((r) => r.value()).toList());
  });

  test('parseKeyValues rejects non objects', () {
    expect(() => parseKeyValues('[1]'), throwsFormatException);
    expect(() => parseKeyValues('{'), throwsFormatException);
  });

  test('store round trip keeps a null type as auto', () {
    const rows = [KeyValue(key: 'a', raw: '1'), KeyValue(key: 'b', raw: '2', type: ValueType.text)];
    final back = keyValuesFromStore(keyValuesToStore(rows));
    expect(back.first.type, isNull);
    expect(back.last.type, ValueType.text);
  });

  test('badge cycles through all types', () {
    expect(ValueType.date.next, ValueType.text);
  });
}
