import 'package:flutter/material.dart' hide Chip;
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

import '../../data/event_rules.dart';
import '../../data/forms.dart';
import '../../data/key_value.dart';
import '../controls/basics.dart';
import '../controls/chips.dart';
import '../controls/fields.dart';
import '../controls/key_value_rows.dart';
import '../help.dart';

const _currencies = ['USD', 'EUR', 'GBP', 'RON'];
const _products = ['pro_monthly', 'pro_yearly', 'coins_100'];
const _startOptions = {0: 'Now', 1: '1 day ago', 30: '30 days ago'};

String _startLabel(int daysAgo) =>
    _startOptions[daysAgo] ?? '$daysAgo days ago';

class EventFormFields extends StatelessWidget {
  const EventFormFields({
    super.key,
    required this.form,
    required this.update,
    required this.suggestions,
    required this.error,
    required this.onTrack,
    this.onSendAnyway,
  });

  final EventForm form;
  final void Function(EventForm Function(EventForm)) update;
  final List<String> suggestions;
  final String? error;
  final VoidCallback onTrack;
  final VoidCallback? onSendAnyway;

  @override
  Widget build(BuildContext context) {
    final detail = [
      summary(form.properties),
      form.tags.map((t) => 'tag $t').join(', '),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuggestField(
          value: form.name,
          onChanged: (v) => update((f) => f.copyWith(name: v)),
          suggestions: suggestions,
          mono: true,
          error: error,
          onSubmitted: onTrack,
        ),
        if (isReservedEventName(form.name) && onSendAnyway != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextAction('Send anyway', onSendAnyway!),
          ),
        FoldRow(
          'Properties and tags',
          detail.isEmpty ? 'none' : detail,
          info: Help.eventPropertiesAndTags,
          children: [
            KeyValueRows(
              rows: form.properties,
              onChanged: (v) => update((f) => f.copyWith(properties: v)),
              label: 'Properties',
              suggestedKeys: const ['level', 'source'],
            ),
            const SizedBox(height: 10),
            ChipInput(
              values: form.tags,
              onChanged: (v) => update((f) => f.copyWith(tags: v)),
              label: 'Tags',
              placeholder: 'Add tag',
              max: maxTags,
            ),
          ],
        ),
      ],
    );
  }
}

class PurchaseFormFields extends StatelessWidget {
  const PurchaseFormFields({
    super.key,
    required this.form,
    required this.update,
  });

  final PurchaseForm form;
  final void Function(PurchaseForm Function(PurchaseForm)) update;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segment<TransactionType>(
          TransactionType.values,
          form.type,
          (v) => update((f) => f.copyWith(type: v)),
          label: (t) => t.name[0].toUpperCase() + t.name.substring(1),
        ),
        const SizedBox(height: 10),
        MoneyField(
          amount: form.amount,
          onChanged: (v) => update((f) => f.copyWith(amount: v)),
          currency: form.currency,
        ),
        const SizedBox(height: 10),
        ChipPicker(
          options: _currencies,
          selected: form.currency,
          onSelect: (v) => update((f) => f.copyWith(currency: v.toUpperCase())),
          label: 'Currency',
          otherPlaceholder: 'Code, e.g. JPY',
        ),
        const SizedBox(height: 10),
        ChipPicker(
          options: _products,
          selected: form.productId,
          onSelect: (v) => update((f) => f.copyWith(productId: v)),
          label: 'Product',
          otherPlaceholder: 'product id',
        ),
        FoldRow(
          'Start date',
          _startLabel(form.startDaysAgo),
          info: Help.startDate,
          children: [
            ChipRow(
              _startOptions.values.toList(),
              _startLabel(form.startDaysAgo),
              (label) => update(
                (f) => f.copyWith(
                  startDaysAgo: _startOptions.entries
                      .firstWhere((e) => e.value == label)
                      .key,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
