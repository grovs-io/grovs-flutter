import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/call_code.dart';

void main() {
  test('no arguments', () => expect(callCode('pauseInAppMessages'), 'pauseInAppMessages()'));

  test('one argument per line, strings quoted, maps indented', () {
    expect(
      callCode('track', [('name', 'a'), ('properties', {'level': 3}), ('tags', null)]),
      'track(\n'
      '  name = "a",\n'
      '  properties = {\n'
      '    level: 3\n'
      '  },\n'
      '  tags = null\n'
      ')',
    );
  });

  test('lists and empty maps', () {
    expect(render(['a', 1]), '["a", 1]');
    expect(render(<String, Object?>{}), '{}');
  });

  test('dates render as quoted yyyy-MM-dd', () {
    expect(render(DateTime(2026, 3, 7)), '"2026-03-07"');
  });
}
