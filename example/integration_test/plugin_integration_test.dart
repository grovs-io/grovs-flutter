// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final Grovs plugin = Grovs();
    final String? version = await plugin.getPlatformVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version?.isNotEmpty, true);
  });

  for (final invalid in [
    '',
    'not a url',
    'relative/path',
    'https://',
    'mailto:a@b.c',
  ]) {
    testWidgets('handleUrl rejects "$invalid"', (WidgetTester tester) async {
      await expectLater(
        Grovs().handleUrl(invalid),
        throwsA(
          isA<GrovsException>().having(
            (e) => e.code,
            'code',
            'INVALID_ARGUMENT',
          ),
        ),
      );
    });
  }

  // Pass a real link with --dart-define=GROVS_TEST_LINK=<link>.
  const link = String.fromEnvironment('GROVS_TEST_LINK');
  testWidgets('handleUrl delivers a link', (WidgetTester tester) async {
    final received = Grovs().onDeeplinkReceived.first;
    expect(await Grovs().handleUrl(link), true);
    await received.timeout(const Duration(seconds: 30));
  }, skip: link.isEmpty);
}
