import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart' hide Chip;

import '../theme.dart';
import 'basics.dart';
import 'fields.dart';
import 'info.dart';

const _dashLength = 6.0;
const _dashGap = 4.0;

class Chip extends StatelessWidget {
  const Chip(
    this.text,
    this.onTap, {
    super.key,
    this.selected = false,
    this.dashed = false,
    this.removable = false,
    this.color,
  });

  final String text;
  final VoidCallback onTap;
  final bool selected;
  final bool dashed;
  final bool removable;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final shape = BorderRadius.circular(50);
    final textColor =
        color ??
        (selected
            ? c.accent
            : dashed
            ? c.textMuted
            : c.text);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(
          foregroundPainter: dashed ? _DashedBorderPainter(c.border) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            foregroundDecoration: dashed
                ? null
                : BoxDecoration(
                    borderRadius: shape,
                    border: Border.all(color: selected ? c.accent : c.border),
                  ),
            decoration: BoxDecoration(
              color: selected ? c.accentSoft : c.background,
              borderRadius: shape,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  maxLines: 1,
                  style: AppType.caption.copyWith(color: textColor),
                ),
                if (removable)
                  Text(
                    ' ×',
                    style: AppType.caption.copyWith(color: c.textFaint),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(0.5);
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(bounds.height / 2)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final PathMetric metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += _dashLength + _dashGap) {
        canvas.drawPath(metric.extractPath(at, at + _dashLength), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

class ChipRow extends StatelessWidget {
  const ChipRow(
    this.values,
    this.selected,
    this.onPick, {
    super.key,
    this.label,
  });

  final List<String> values;
  final String? selected;
  final ValueChanged<String> onPick;
  final String Function(String)? label;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Chip(
              label?.call(values[i]) ?? values[i],
              () => onPick(values[i]),
              selected: values[i] == selected,
            ),
          ],
        ],
      ),
    );
  }
}

class ChipPicker extends StatefulWidget {
  const ChipPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.label,
    this.info,
    this.otherLabel = 'Other…',
    this.otherPlaceholder,
    this.display,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final String? label;
  final Info? info;
  final String otherLabel;
  final String? otherPlaceholder;
  final String Function(String)? display;

  @override
  State<ChipPicker> createState() => _ChipPickerState();
}

class _ChipPickerState extends State<ChipPicker> {
  bool _editingOther = false;
  String _typed = '';

  String? get _custom =>
      widget.selected.isNotEmpty && !widget.options.contains(widget.selected)
      ? widget.selected
      : null;

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.otherPlaceholder;
    final showOther = placeholder != null && (_editingOther || _custom != null);
    final otherText = _editingOther ? _typed : _custom ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) FieldLabel(widget.label!, info: widget.info),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in widget.options) ...[
                Chip(widget.display?.call(option) ?? option, () {
                  setState(() => _editingOther = false);
                  widget.onSelect(option);
                }, selected: option == widget.selected && !_editingOther),
                const SizedBox(width: 6),
              ],
              if (placeholder != null)
                Chip(
                  otherText.isEmpty ? widget.otherLabel : otherText,
                  () => setState(() {
                    _typed = _custom ?? '';
                    _editingOther = true;
                  }),
                  selected: showOther,
                  dashed: !showOther,
                ),
            ],
          ),
        ),
        if (showOther)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: AppTextField(
              value: otherText,
              placeholder: placeholder,
              onChanged: (text) {
                setState(() {
                  _typed = text;
                  _editingOther = true;
                });
                widget.onSelect(text);
              },
            ),
          ),
      ],
    );
  }
}

class ChipInput extends StatefulWidget {
  const ChipInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.label,
    this.info,
    this.placeholder = 'Add',
    this.max,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String? label;
  final Info? info;
  final String placeholder;
  final int? max;

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _controller.text.trim().isNotEmpty) {
        _commit(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String text) {
    final added = text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && !widget.values.contains(part))
        .toSet()
        .toList();
    if (added.isNotEmpty) widget.onChanged([...widget.values, ...added]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final max = widget.max;
    final overLimit = max != null && widget.values.length > max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null || max != null)
          FieldLabel(
            widget.label ?? '',
            trailing: max == null ? null : '${widget.values.length} of $max',
            info: widget.info,
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: overLimit ? c.error : c.border),
          ),
          child: Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final value in widget.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Chip(
                    value,
                    () => widget.onChanged(
                      widget.values.where((v) => v != value).toList(),
                    ),
                    removable: true,
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 90),
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    style: AppType.body.copyWith(color: c.text),
                    cursorColor: c.accent,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    scrollPadding: fieldScrollPadding,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (text) {
                      if (text.endsWith(',')) _commit(text);
                    },
                    onSubmitted: _commit,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.placeholder,
                      hintStyle: AppType.body.copyWith(color: c.textFaint),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
