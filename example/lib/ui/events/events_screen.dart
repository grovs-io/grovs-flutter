import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter/services.dart';

import '../../app_graph.dart';
import '../../data/key_value.dart';
import '../controls/basics.dart';
import '../controls/chips.dart';
import '../controls/fields.dart';
import '../controls/key_value_rows.dart';
import '../controls/sheet.dart';
import '../help.dart';
import '../theme.dart';
import 'event_forms.dart';
import 'events_controller.dart';

bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = AppGraph.events;
    return ListenableBuilder(
      listenable: events,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTitle('Events'),
            const SectionHeader('Custom event', info: Help.customEvent),
            EventFormFields(
              form: events.event,
              update: events.updateEvent,
              suggestions: events.eventSuggestions,
              error: events.eventError,
              onTrack: events.trackEvent,
              onSendAnyway: () => events.trackEvent(force: true),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppButton(
                events.eventError ?? 'Track',
                events.trackEvent,
                enabled: events.eventError == null,
              ),
            ),
            const SectionHeader('Screen view', info: Help.screenView),
            _ScreenRow(events),
            const SectionHeader('Setup'),
            FoldRow(
              'Global tags',
              events.globalTags.isEmpty ? 'none' : events.globalTags.join(', '),
              info: Help.globalTags,
              children: [
                ChipInput(
                  values: events.globalTags,
                  onChanged: events.applyGlobalTags,
                  placeholder: 'Add tag',
                ),
              ],
            ),
            FoldRow(
              'Screen aliases',
              events.aliases.isEmpty
                  ? 'none'
                  : events.aliases.map((a) => '${a.key} → ${a.raw}').join(', '),
              info: Help.screenAliases,
              children: [_AliasesEditor(events)],
            ),
            const SectionHeader('Purchase', info: Help.purchase),
            _PurchaseSection(events),
          ],
        ),
      ),
    );
  }
}

class _ScreenRow extends StatelessWidget {
  const _ScreenRow(this.events);

  final EventsController events;

  void _editProperties(BuildContext context) {
    showAppSheet(
      context,
      builder: (sheet) => ListenableBuilder(
        listenable: events,
        builder: (_, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Screen properties',
                style: AppType.heading.copyWith(
                  color: GrovsColors.of(sheet).text,
                ),
              ),
            ),
            KeyValueRows(
              rows: events.screen.properties,
              onChanged: (v) =>
                  events.updateScreen((s) => s.copyWith(properties: v)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppButton('Save and track', () {
                events.trackScreen();
                Navigator.of(sheet).pop();
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                value: events.screen.name,
                onChanged: (v) =>
                    events.updateScreen((s) => s.copyWith(name: v)),
                onSubmitted: events.trackScreen,
              ),
            ),
            const SizedBox(width: 6),
            AppButton(
              'Track',
              events.trackScreen,
              small: true,
              enabled: events.screen.name.trim().isNotEmpty,
              onLongPress: () => _editProperties(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ChipRow(
            events.screenSuggestions,
            events.screen.name,
            (v) => events.updateScreen((s) => s.copyWith(name: v)),
          ),
        ),
      ],
    );
  }
}

class _AliasesEditor extends StatefulWidget {
  const _AliasesEditor(this.events);

  final EventsController events;

  @override
  State<_AliasesEditor> createState() => _AliasesEditorState();
}

class _AliasesEditorState extends State<_AliasesEditor> {
  late List<KeyValue> _draft = widget.events.aliases;

  @override
  void didUpdateWidget(_AliasesEditor old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.events.aliases, widget.events.aliases)) {
      _draft = widget.events.aliases;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyValueRows(
          rows: _draft,
          onChanged: (v) => setState(() => _draft = v),
          textOnly: true,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppButton(
            'Apply aliases',
            () => widget.events.applyAliases(_draft),
            style: ButtonStyleKind.outline,
          ),
        ),
      ],
    );
  }
}

class _PurchaseSection extends StatefulWidget {
  const _PurchaseSection(this.events);

  final EventsController events;

  @override
  State<_PurchaseSection> createState() => _PurchaseSectionState();
}

class _PurchaseSectionState extends State<_PurchaseSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final events = widget.events;
    final purchase = events.purchase;
    final storeTitle = _isIos
        ? 'App Store transaction ID'
        : 'Google Play purchase JSON';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                purchase.fullLabel(),
                events.logPurchase,
                style: _expanded
                    ? ButtonStyleKind.primary
                    : ButtonStyleKind.outline,
                enabled: purchase.isValid(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              tooltip: 'Edit purchase',
              constraints: const BoxConstraints.tightFor(
                width: minTouch,
                height: minTouch,
              ),
              padding: EdgeInsets.zero,
              icon: Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: c.textMuted,
              ),
            ),
          ],
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PurchaseFormFields(
                  form: purchase,
                  update: events.updatePurchase,
                ),
                FoldRow(
                  storeTitle,
                  purchase.storeId.trim().isEmpty ? 'empty' : 'pasted',
                  info: Help.storePurchase,
                  children: [
                    AppTextField(
                      value: purchase.storeId,
                      onChanged: (v) =>
                          events.updatePurchase((p) => p.copyWith(storeId: v)),
                      placeholder: _isIos
                          ? 'transaction id'
                          : 'purchase.originalJson',
                      mono: true,
                      singleLine: _isIos,
                      minLines: _isIos ? null : 4,
                      keyboardType: _isIos
                          ? TextInputType.number
                          : TextInputType.multiline,
                      textInputAction: _isIos
                          ? TextInputAction.done
                          : TextInputAction.newline,
                      inputFormatters: _isIos
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : null,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      _isIos ? 'Log App Store purchase' : 'Log Play purchase',
                      events.logStorePurchase,
                      style: ButtonStyleKind.outline,
                      enabled: purchase.storeId.trim().isNotEmpty,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
