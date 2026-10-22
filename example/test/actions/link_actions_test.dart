import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/actions/link_actions.dart';
import 'package:grovs_example/data/forms.dart';
import '../fake_grovs.dart';

void main() {
  late FakeGrovs grovs;
  setUp(() async => grovs = await FakeGrovs.install());
  tearDown(() => grovs.uninstall());

  test('generate sends only what is turned on', () async {
    final result = await LinkActions.generate(const LinkForm()).run();
    final args = grovs.lastArgs('generateLink');
    expect(args['title'], 'Test title');
    expect(args['data'], {'param1': 'Test value'});
    expect(args['tracking'], isNull);
    expect(args['customRedirects'], isNull);
    expect(args['imageURL'], isNull);
    expect(args['tags'], isNull);
    expect(result.value, 'https://test.sqd.link/abc');
  });

  test('generate with UTM and one redirect', () async {
    final form = const LinkForm().copyWith(
      utmOn: true,
      redirectsOn: true,
      ios: const Redirect('', false),
    );
    await LinkActions.generate(form).run();
    final args = grovs.lastArgs('generateLink');
    expect((args['tracking'] as Map)['utm_source'], 'test_source');
    expect((args['customRedirects'] as Map)['ios'], isNull);
    expect((args['customRedirects'] as Map)['android'], isNotNull);
  });

  test('generate trims the image and redirect URLs', () async {
    final form = const LinkForm().copyWith(
      imageUrl: ' https://img.example.com/a.png ',
      redirectsOn: true,
      ios: const Redirect(' https://example.com/ios ', false),
    );
    await LinkActions.generate(form).run();
    final args = grovs.lastArgs('generateLink');
    expect(args['imageURL'], 'https://img.example.com/a.png');
    expect(
      ((args['customRedirects'] as Map)['ios'] as Map)['url'],
      'https://example.com/ios',
    );
  });

  test('generate passes the platform overrides', () async {
    final form = const LinkForm().copyWith(
      previewIos: TriState.on,
      clipboardAndroid: TriState.off,
    );
    await LinkActions.generate(form).run();
    final args = grovs.lastArgs('generateLink');
    expect(args['showPreviewIos'], true);
    expect(args['showPreviewAndroid'], isNull);
    expect(args['copyToClipboardAndroid'], false);
  });

  test('details counts fields', () async {
    final result = await LinkActions.details('abc').run();
    expect(grovs.lastArgs('linkDetails')['path'], 'abc');
    expect(result.detail, endsWith('fields'));
  });
}
