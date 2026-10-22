import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/link_history_json.dart';
import 'package:grovs_example/actions/test_log.dart';

void main() {
  test('round trip keeps link entries', () {
    final log = TestLog()..recordLinkOpen('https://l/a', {'k': 1}, null);
    final back = decodeLinkEntries(encodeLinkEntries(log.entries));
    expect(back.single.link, 'https://l/a');
    expect(back.single.code, log.entries.single.code);
    expect(back.single.time, log.entries.single.time);
  });

  test('bad or missing JSON loads nothing', () {
    expect(decodeLinkEntries(null), isEmpty);
    expect(decodeLinkEntries('not json'), isEmpty);
  });
}
