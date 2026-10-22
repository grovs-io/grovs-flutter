import 'package:flutter/material.dart';

import '../../actions/log.dart';
import '../../data/forms.dart';
import '../../data/strings.dart';
import '../theme.dart';
import 'clipboard.dart';
import 'info.dart';

/// Smallest tap target height and width, so neighbours are hard to hit by mistake.
const double minTouch = 40;

/// Height of text fields and buttons, so they line up when side by side.
const double fieldHeight = 44;

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppType.title.copyWith(
                color: GrovsColors.of(context).text,
              ),
            ),
          ),
          if (action != null) TextAction(action!, onAction ?? () {}),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.text, {
    super.key,
    this.action,
    this.onAction,
    this.trailing,
    this.info,
  });

  final String text;
  final String? action;
  final VoidCallback? onAction;
  final String? trailing;
  final Info? info;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Row(
        children: [
          _LabelWithInfo(text, AppType.label, c.textMuted, info),
          if (trailing != null)
            Text(
              trailing!,
              style: AppType.caption.copyWith(color: c.textFaint),
            ),
          if (action != null) TextAction(action!, onAction ?? () {}),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(
    this.text, {
    super.key,
    this.trailing,
    this.action,
    this.onAction,
    this.info,
  });

  final String text;
  final String? trailing;
  final String? action;
  final VoidCallback? onAction;
  final Info? info;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _LabelWithInfo(text, AppType.label, c.textMuted, info),
          if (trailing != null)
            Text(
              trailing!,
              style: AppType.caption.copyWith(color: c.textMuted),
            ),
          if (action != null) TextAction(action!, onAction ?? () {}),
        ],
      ),
    );
  }
}

/// A label that takes the free width of its row, with an optional "?" right after the text.
class _LabelWithInfo extends StatelessWidget {
  const _LabelWithInfo(this.text, this.style, this.color, this.info);

  final String text;
  final TextStyle style;
  final Color color;
  final Info? info;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(text, style: style.copyWith(color: color)),
          ),
          if (info != null) InfoButton(info!),
        ],
      ),
    );
  }
}

class HelpText extends StatelessWidget {
  const HelpText(this.text, {super.key, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: AppType.caption.copyWith(color: isError ? c.error : c.textMuted),
      ),
    );
  }
}

class TextAction extends StatelessWidget {
  const TextAction(
    this.text,
    this.onTap, {
    super.key,
    this.color,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onTap;
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: minTouch,
            minWidth: minTouch,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              widthFactor: 1,
              child: Text(
                text,
                style: AppType.label.copyWith(
                  color: enabled ? color ?? c.accent : c.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow(
    this.label, {
    super.key,
    this.onTap,
    this.showDivider = true,
    this.info,
    this.trailing = const [],
  });

  final String label;
  final VoidCallback? onTap;
  final bool showDivider;
  final Info? info;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _LabelWithInfo(label, AppType.body, c.text, info),
            for (final widget in trailing) ...[
              const SizedBox(width: 8),
              widget,
            ],
          ],
        ),
      ),
    );
    return Column(
      children: [
        onTap == null ? row : InkWell(onTap: onTap, child: row),
        if (showDivider) Divider(height: 1, thickness: 1, color: c.divider),
      ],
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow(
    this.label,
    this.value,
    this.onChanged, {
    super.key,
    this.supporting,
    this.showDivider = true,
    this.info,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? supporting;
  final bool showDivider;
  final Info? info;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return SettingRow(
      label,
      onTap: () => onChanged(!value),
      showDivider: showDivider,
      info: info,
      trailing: [
        if (supporting != null)
          Text(
            supporting!,
            style: AppType.caption.copyWith(color: c.textMuted),
          ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: c.accent,
          activeThumbColor: Colors.white,
          inactiveTrackColor: c.neutralDot,
          inactiveThumbColor: Colors.white,
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
    );
  }
}

class Segment<T> extends StatelessWidget {
  const Segment(
    this.options,
    this.selected,
    this.onSelect, {
    super.key,
    this.compact = false,
    this.label,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelect;
  final bool compact;
  final String Function(T)? label;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.chipFill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(child: _segmentCell(c, options[i])),
          ],
        ],
      ),
    );
  }

  Widget _segmentCell(GrovsColors c, T option) {
    final on = option == selected;
    return Semantics(
      selected: on,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(option),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
          decoration: BoxDecoration(
            color: on ? c.background : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label?.call(option) ?? option.toString(),
            maxLines: 1,
            style: AppType.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: on ? c.text : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class TriStateRow extends StatelessWidget {
  const TriStateRow(
    this.label,
    this.value,
    this.onChange, {
    super.key,
    this.info,
  });

  final String label;
  final TriState value;
  final ValueChanged<TriState> onChange;
  final Info? info;

  @override
  Widget build(BuildContext context) {
    return SettingRow(
      label,
      info: info,
      trailing: [
        SizedBox(
          width: 170,
          child: Segment<TriState>(
            TriState.values,
            value,
            onChange,
            compact: true,
            label: (state) => state.label,
          ),
        ),
      ],
    );
  }
}

extension LogStateColors on LogState {
  Color color(BuildContext context) {
    final c = GrovsColors.of(context);
    return switch (this) {
      LogState.ok => c.ok,
      LogState.warning => c.warning,
      LogState.error => c.error,
      LogState.neutral => c.neutralDot,
    };
  }

  Color softColor(BuildContext context) {
    final c = GrovsColors.of(context);
    return switch (this) {
      LogState.ok => c.okSoft,
      LogState.warning => c.warningSoft,
      LogState.error => c.errorSoft,
      LogState.neutral => c.chipFill,
    };
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot(this.state, {super.key});

  final LogState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: state.color(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, this.state, {super.key});

  final String text;
  final LogState state;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: state.softColor(context),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: AppType.caption.copyWith(
          fontWeight: FontWeight.w500,
          color: state == LogState.neutral ? c.textMuted : state.color(context),
        ),
      ),
    );
  }
}

enum ButtonStyleKind { primary, outline }

class AppButton extends StatelessWidget {
  const AppButton(
    this.text,
    this.onTap, {
    super.key,
    this.style = ButtonStyleKind.primary,
    this.enabled = true,
    this.small = false,
    this.onLongPress,
  });

  final String text;
  final VoidCallback onTap;
  final ButtonStyleKind style;
  final bool enabled;
  final bool small;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final shape = BorderRadius.circular(small ? 8 : 9);
    final primary = style == ButtonStyleKind.primary;
    final background = !enabled
        ? c.neutralDot
        : primary
        ? c.accent
        : c.background;
    final foreground = !enabled || primary ? Colors.white : c.text;
    // Long press stays available on a disabled button so its saved values can still be edited.
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(minHeight: fieldHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: shape,
            border: enabled && !primary ? Border.all(color: c.border) : null,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (small ? AppType.caption : AppType.bodyStrong).copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class FoldRow extends StatefulWidget {
  const FoldRow(
    this.title,
    this.summary, {
    super.key,
    this.initiallyExpanded = false,
    this.info,
    this.children = const [],
  });

  final String title;
  final String summary;
  final bool initiallyExpanded;
  final Info? info;
  final List<Widget> children;

  @override
  State<FoldRow> createState() => _FoldRowState();
}

class _FoldRowState extends State<FoldRow> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _LabelWithInfo(
                    widget.title,
                    AppType.bodyStrong,
                    c.text,
                    widget.info,
                  ),
                  if (!_expanded)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        widget.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption.copyWith(color: c.textMuted),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: c.textFaint,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Divider(height: 1, thickness: 1, color: c.divider),
      ],
    );
  }
}

class CopyRow extends StatelessWidget {
  const CopyRow(
    this.label,
    this.value, {
    super.key,
    this.emptyText = 'Not set',
    this.info,
  });

  final String label;
  final String? value;
  final String emptyText;
  final Info? info;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final text = value;
    return SettingRow(
      label,
      onTap: text == null ? null : () => copyText(context, text),
      info: info,
      trailing: [
        Text(
          text == null ? emptyText : middleEllipsis(text),
          style: AppType.mono.copyWith(color: c.textMuted),
        ),
        if (text != null)
          Text('Copy', style: AppType.label.copyWith(color: c.accent)),
      ],
    );
  }
}
