import 'package:flutter/material.dart' hide Chip;
import 'package:flutter/services.dart';

import '../../data/key_value.dart';
import '../theme.dart';
import 'basics.dart';
import 'chips.dart';
import 'fields.dart';
import 'info.dart';
import 'sheet.dart';

class KeyValueRows extends StatelessWidget {
  const KeyValueRows({
    super.key,
    required this.rows,
    required this.onChanged,
    this.label,
    this.info,
    this.suggestedKeys = const [],
    this.textOnly = false,
  });

  final List<KeyValue> rows;
  final ValueChanged<List<KeyValue>> onChanged;
  final String? label;
  final Info? info;
  final List<String> suggestedKeys;
  final bool textOnly;

  void _replace(int index, KeyValue row) => onChanged([...rows]..[index] = row);

  void _openJsonSheet(BuildContext context) {
    showAppSheet(
      context,
      builder: (sheetContext) => _JsonPasteSheet(
        rows: rows,
        onApply: (parsed) {
          Navigator.of(sheetContext).pop();
          onChanged(parsed);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final unusedKeys = suggestedKeys
        .where((key) => rows.every((row) => row.key != key))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          FieldLabel(
            label!,
            info: info,
            action: textOnly ? null : 'Paste JSON',
            onAction: () => _openJsonSheet(context),
          ),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: AppTextField(
                    key: ValueKey('kvKey$i'),
                    value: rows[i].key,
                    placeholder: 'key',
                    textInputAction: TextInputAction.next,
                    onChanged: (text) =>
                        _replace(i, rows[i].copyWith(key: text)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 12,
                  child: AppTextField(
                    key: ValueKey('kvValue$i'),
                    value: rows[i].raw,
                    placeholder: 'value',
                    onChanged: (text) =>
                        _replace(i, rows[i].copyWith(raw: text)),
                    trailing: textOnly
                        ? null
                        : _TypeBadge(
                            rows[i].resolvedType,
                            () => _replace(
                              i,
                              rows[i].copyWith(type: rows[i].resolvedType.next),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 5),
                TextAction(
                  '×',
                  () => onChanged([...rows]..removeAt(i)),
                  color: c.textFaint,
                ),
              ],
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Chip(
                '+ Add',
                () => onChanged([...rows, const KeyValue(key: '', raw: '')]),
                dashed: true,
              ),
              for (final key in unusedKeys) ...[
                const SizedBox(width: 8),
                Chip(
                  '+ $key',
                  () => onChanged([...rows, KeyValue(key: key, raw: '')]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type, this.onTap);

  final ValueType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      onTapHint: 'Change type',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            type.badge,
            style: AppType.monoSmall.copyWith(
              color: GrovsColors.of(context).textFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _JsonPasteSheet extends StatefulWidget {
  const _JsonPasteSheet({required this.rows, required this.onApply});

  final List<KeyValue> rows;
  final ValueChanged<List<KeyValue>> onApply;

  @override
  State<_JsonPasteSheet> createState() => _JsonPasteSheetState();
}

class _JsonPasteSheetState extends State<_JsonPasteSheet> {
  late String _text = widget.rows.isEmpty ? '{}' : keyValuesToJson(widget.rows);
  String? _error;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted != null) {
      setState(() {
        _text = pasted;
        _error = null;
      });
    }
  }

  void _apply() {
    try {
      widget.onApply(parseKeyValues(_text));
    } on FormatException {
      setState(() => _error = 'Not valid JSON');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Paste JSON',
            style: AppType.heading.copyWith(
              color: GrovsColors.of(context).text,
            ),
          ),
        ),
        AppTextField(
          value: _text,
          mono: true,
          singleLine: false,
          minLines: 7,
          textInputAction: TextInputAction.newline,
          onChanged: (text) => setState(() {
            _text = text;
            _error = null;
          }),
        ),
        HelpText(
          _error ?? 'An object, e.g. {"level": 3}',
          isError: _error != null,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  'Paste',
                  _paste,
                  style: ButtonStyleKind.outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: AppButton('Apply', _apply)),
            ],
          ),
        ),
      ],
    );
  }
}
