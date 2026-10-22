import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../actions/log.dart';
import '../../app_graph.dart';
import '../controls/basics.dart';
import '../controls/clipboard.dart';
import '../controls/fields.dart';
import '../controls/sheet.dart';
import '../help.dart';
import '../theme.dart';
import 'link_form_fields.dart';
import 'links_controller.dart';
import 'open_link.dart';
import 'qr_sheet.dart';

class LinksScreen extends StatelessWidget {
  const LinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final links = AppGraph.links;
    return ListenableBuilder(
      listenable: links,
      builder: (context, _) => Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenTitle('Links', action: 'Reset', onAction: links.reset),
                LinkField(
                  value: links.inspectInput,
                  onChanged: links.setInspectInput,
                  label: 'Inspect a link',
                  info: Help.inspect,
                  placeholder: 'Paste a link to inspect',
                  showPath: true,
                  onDone: links.inspect,
                ),
                if (links.result case final result?)
                  _LinkResultCard(
                    result,
                    onRunAgain: links.runAgain,
                    onInspect: (link) {
                      links.setInspectInput(link);
                      links.inspect(link);
                    },
                  ),
                const SectionHeader('New link'),
                LinkFormFields(links.form, links.update),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.background.withAlpha(0), c.background],
                ),
              ),
              child: AppButton(
                links.running ? 'Generating…' : 'Generate link',
                links.generate,
                enabled: !links.running,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkResultCard extends StatelessWidget {
  const _LinkResultCard(
    this.result, {
    required this.onRunAgain,
    required this.onInspect,
  });

  final LinkResult result;
  final VoidCallback onRunAgain;
  final ValueChanged<String> onInspect;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final state = result.ok ? LogState.ok : LogState.error;
    final link = result.link;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: state.softColor(context).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: state.color(context).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusDot(state),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.ok ? 'Created · ${result.message}' : 'Failed',
                  style: AppType.caption.copyWith(color: c.textMuted),
                ),
              ),
              IconButton(
                onPressed: onRunAgain,
                tooltip: 'Run again',
                constraints: const BoxConstraints.tightFor(
                  width: minTouch,
                  height: minTouch,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.refresh, color: c.accent),
              ),
            ],
          ),
          if (result.ok && link != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(link, style: AppType.mono.copyWith(color: c.accent)),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextAction('Copy', () => copyText(context, link)),
                TextAction(
                  'Share',
                  () => SharePlus.instance.share(ShareParams(text: link)),
                ),
                TextAction(
                  'QR',
                  () => showAppSheet(context, builder: (_) => QrSheet(link)),
                ),
                TextAction('Open', () => openLinkInApp(context, link)),
                TextAction(
                  platformOpenLabel,
                  () => copyText(context, platformOpenCommand(link)),
                ),
                TextAction('Inspect', () => onInspect(link)),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                result.message,
                style: AppType.caption.copyWith(color: c.error),
              ),
            ),
        ],
      ),
    );
  }
}
