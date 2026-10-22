import 'package:flutter/material.dart' hide Chip;
import 'package:flutter/services.dart';

import '../../data/link_tools.dart';
import '../../data/money.dart';
import '../theme.dart';
import 'basics.dart';
import 'chips.dart';
import 'info.dart';

/// Keeps a focused field clear of the keyboard with room for its label above.
const fieldScrollPadding = EdgeInsets.fromLTRB(20, 28, 20, 16);

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = '',
    this.mono = false,
    this.error = false,
    this.singleLine = true,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.style,
    this.leading,
    this.trailing,
    this.inputFormatters,
    this.minLines,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool mono;
  final bool error;
  final bool singleLine;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final TextStyle? style;
  final Widget? leading;
  final Widget? trailing;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String _) {
    switch (widget.textInputAction) {
      case TextInputAction.next:
        FocusScope.of(context).nextFocus();
      case TextInputAction.done:
        _focus.unfocus();
        widget.onSubmitted?.call();
      default:
        widget.onSubmitted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final borderColor = widget.error
        ? c.error
        : _focus.hasFocus
        ? c.accent
        : c.border;
    final style = (widget.style ?? (widget.mono ? AppType.mono : AppType.body))
        .copyWith(color: c.text);
    return Container(
      constraints: const BoxConstraints(minHeight: fieldHeight),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: widget.singleLine ? 0 : 10,
      ),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: widget.singleLine
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 6),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              style: style,
              cursorColor: c.accent,
              maxLines: widget.singleLine ? 1 : null,
              minLines: widget.singleLine ? null : widget.minLines,
              keyboardType: widget.singleLine
                  ? widget.keyboardType
                  : TextInputType.multiline,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              autocorrect: false,
              enableSuggestions: false,
              scrollPadding: fieldScrollPadding,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: widget.onChanged,
              onSubmitted: _submit,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: style.copyWith(color: c.textFaint),
                contentPadding: EdgeInsets.symmetric(
                  vertical: widget.singleLine ? 12 : 0,
                ),
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 6),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}

class SuggestField extends StatelessWidget {
  const SuggestField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.suggestions,
    this.label,
    this.info,
    this.placeholder = '',
    this.error,
    this.mono = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final List<String> suggestions;
  final String? label;
  final Info? info;
  final String placeholder;
  final String? error;
  final bool mono;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) FieldLabel(label!, info: info),
        AppTextField(
          value: value,
          onChanged: onChanged,
          placeholder: placeholder,
          mono: mono,
          error: error != null,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          trailing: value.isEmpty
              ? null
              : TextAction('✕', () => onChanged(''), color: c.textFaint),
        ),
        if (error != null) HelpText(error!, isError: true),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ChipRow(suggestions.toSet().toList(), value, onChanged),
          ),
      ],
    );
  }
}

class LinkField extends StatelessWidget {
  const LinkField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.info,
    this.placeholder = 'https://',
    this.showPath = false,
    this.onDone,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? label;
  final Info? info;
  final String placeholder;
  final bool showPath;
  final VoidCallback? onDone;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null) return;
    onChanged(text);
    if (showPath) onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final path = showPath ? extractLinkPath(value) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) FieldLabel(label!, info: info),
        AppTextField(
          value: value,
          onChanged: onChanged,
          placeholder: placeholder,
          mono: true,
          keyboardType: TextInputType.url,
          onSubmitted: onDone,
          trailing: TextAction('Paste', _paste),
        ),
        if (value.trim().isNotEmpty)
          if (showPath)
            HelpText(
              path == null ? 'No path found' : 'Path: $path',
              isError: path == null,
            )
          else if (!isWebUrl(value))
            const HelpText(
              'Must start with http:// or https://',
              isError: true,
            ),
      ],
    );
  }
}

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.amount,
    required this.onChanged,
    required this.currency,
  });

  final String amount;
  final ValueChanged<String> onChanged;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final cents = parseAmountToCents(amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          value: amount,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          error: cents == null,
          style: AppType.amount,
          leading: Text(
            currencySymbol(currency),
            style: AppType.amount.copyWith(color: c.textMuted),
          ),
        ),
        HelpText(
          cents != null ? 'Sent as $cents cents' : 'Enter an amount like 4.99',
          isError: cents == null,
        ),
      ],
    );
  }
}
