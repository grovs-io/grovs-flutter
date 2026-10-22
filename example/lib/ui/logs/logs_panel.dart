import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:share_plus/share_plus.dart';

import '../../actions/export_log.dart';
import '../../actions/log.dart';
import '../../app_graph.dart';
import '../../data/strings.dart';
import '../controls/basics.dart';
import '../controls/chips.dart';
import '../controls/clipboard.dart';
import '../theme.dart';

/// The log list and entry detail shown inside the logs sheet.
class LogsPanel extends StatefulWidget {
  const LogsPanel({super.key, required this.filter, this.entryId});

  /// Kept by the caller so the chosen filter survives closing the panel.
  final ValueNotifier<LogFilter> filter;

  /// Opens straight on this entry. Dismissing it then closes the panel
  /// instead of going back to the list.
  final int? entryId;

  @override
  State<LogsPanel> createState() => _LogsPanelState();
}

class _LogsPanelState extends State<LogsPanel> {
  late int? _selectedId = widget.entryId;
  late bool _openedOnEntry = widget.entryId != null;

  @override
  void initState() {
    super.initState();
    AppGraph.panel.addListener(_onPanel);
  }

  @override
  void dispose() {
    AppGraph.panel.removeListener(_onPanel);
    super.dispose();
  }

  /// The panel can be asked to show another entry, or to close, while open.
  void _onPanel() {
    final panel = AppGraph.panel.value;
    if (!panel.open) {
      if (ModalRoute.of(context)?.isActive ?? false) {
        Navigator.of(context).pop();
      }
    } else if (panel.entryId != null && panel.entryId != _selectedId) {
      setState(() {
        _selectedId = panel.entryId;
        _openedOnEntry = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppGraph.log, widget.filter]),
      builder: (context, _) {
        final entries = AppGraph.log.entries;
        final selected = entries.where((e) => e.id == _selectedId).firstOrNull;
        final backToList = selected != null && !_openedOnEntry;
        return PopScope(
          canPop: !backToList,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _selectedId = null);
          },
          child: selected != null
              ? _LogDetail(
                  selected,
                  onBack: () => setState(() => _selectedId = null),
                )
              : _LogList(
                  entries,
                  widget.filter.value,
                  onFilter: (f) => widget.filter.value = f,
                  onSelect: (e) => setState(() => _selectedId = e.id),
                ),
        );
      },
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList(
    this.entries,
    this.filter, {
    required this.onFilter,
    required this.onSelect,
  });

  final List<LogEntry> entries;
  final LogFilter filter;
  final ValueChanged<LogFilter> onFilter;
  final ValueChanged<LogEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final errors = entries.where((e) => e.state == LogState.error).length;
    final shown = entries.where(filter.matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Logs',
                  style: AppType.heading.copyWith(color: c.text),
                ),
              ),
              TextAction('Share', () => _share(entries)),
              TextAction('Clear', AppGraph.log.clear, color: c.textMuted),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in LogFilter.values) ...[
                  if (f != LogFilter.values.first) const SizedBox(width: 8),
                  _filterChip(c, f, errors),
                ],
              ],
            ),
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nothing logged yet',
              style: AppType.caption.copyWith(color: c.textMuted),
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: shown.length,
            itemBuilder: (_, i) =>
                _LogRow(shown[i], onTap: () => onSelect(shown[i])),
            separatorBuilder: (_, _) =>
                Divider(height: 1, thickness: 1, color: c.divider),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(GrovsColors c, LogFilter f, int errors) {
    final countErrors = f == LogFilter.errors && errors > 0;
    return Chip(
      countErrors ? '${f.label} $errors' : f.label,
      () => onFilter(f),
      selected: f == filter,
      color: countErrors && f != filter ? c.error : null,
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow(this.entry, {required this.onTap});

  final LogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final action = entry.action;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            StatusDot(entry.state),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                entry.type.label,
                style: AppType.monoSmall.copyWith(color: c.textMuted),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodyStrong.copyWith(color: c.text),
                  ),
                  if (entry.detail.trim().isNotEmpty)
                    Text(
                      entry.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.caption.copyWith(color: c.textMuted),
                    ),
                ],
              ),
            ),
            if (action != null && action.repeatable) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => AppGraph.rerun(action),
                tooltip: 'Run again',
                constraints: const BoxConstraints.tightFor(
                  width: minTouch,
                  height: minTouch,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.refresh, color: c.accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogDetail extends StatelessWidget {
  const _LogDetail(this.entry, {required this.onBack});

  final LogEntry entry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final text = entry.code.trim().isEmpty ? entry.detail : entry.code;
    final action = entry.action;
    final link = entry.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                constraints: const BoxConstraints.tightFor(
                  width: minTouch,
                  height: minTouch,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back, color: c.textMuted),
              ),
              const SizedBox(width: 8),
              StatusDot(entry.state),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.heading.copyWith(color: c.text),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatClock(entry.time, seconds: true),
                style: AppType.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(text, style: AppType.mono.copyWith(color: c.text)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  'Copy',
                  () => copyText(context, text),
                  style: ButtonStyleKind.outline,
                ),
              ),
              if (action != null && action.repeatable) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    'Run again',
                    () => AppGraph.rerun(action),
                    style: ButtonStyleKind.outline,
                  ),
                ),
              ],
              if (link != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    'Inspect link',
                    () => AppGraph.links.inspect(link),
                    style: ButtonStyleKind.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _share(List<LogEntry> entries) async {
  final project = AppGraph.config.useTestEnvironment ? 'test' : 'prod';
  final header =
      'Grovs test app log\nDevice: ${await _deviceLine()}\n'
      'Plugin: $pluginVersion · Project: $project';
  final text = exportLog(entries, header, (t) => formatClock(t, seconds: true));
  await SharePlus.instance.share(ShareParams(text: text));
}

Future<String> _deviceLine() async {
  try {
    final info = DeviceInfoPlugin();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => await info.androidInfo.then(
        (d) => '${d.manufacturer} ${d.model} · Android ${d.version.release}',
      ),
      TargetPlatform.iOS => await info.iosInfo.then(
        (d) => '${d.modelName} · iOS ${d.systemVersion}',
      ),
      _ => 'unknown',
    };
  } catch (_) {
    return 'unknown';
  }
}
