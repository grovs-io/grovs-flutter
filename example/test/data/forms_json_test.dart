import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_example/data/forms.dart';
import 'package:grovs_example/data/forms_json.dart';
import 'package:grovs_example/data/key_value.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

void main() {
  test('link form round trip', () {
    final form = const LinkForm().copyWith(
      tags: ['a'],
      utmOn: true,
      previewIos: TriState.off,
      android: const Redirect('https://x.y', true),
      data: const [KeyValue(key: 'n', raw: '1', type: ValueType.text)],
    );
    expect(decodeLinkForm(encodeLinkForm(form)), form);
  });

  test('bad JSON gives the defaults', () {
    expect(decodeLinkForm('{'), const LinkForm());
    expect(decodeEventForm(null), const EventForm());
  });

  test('purchase labels', () {
    const form = PurchaseForm();
    expect(form.label(), 'Log \$4.99 buy');
    expect(form.fullLabel(), 'Log \$4.99 buy · USD · pro_monthly');
    expect(const PurchaseForm(amount: 'x').isValid(), isFalse);
    expect(
      const PurchaseForm(type: TransactionType.refund).label(),
      'Log \$4.99 refund',
    );
  });

  test('summaries', () {
    expect(
      const LinkForm().moreSummary(),
      'UTM off · no tags · no image · no redirects',
    );
    expect(const LinkForm().overridesSummary(), 'all default');
    expect(const LinkForm(previewIos: TriState.on).overridesSummary(), '1 set');
  });
}
