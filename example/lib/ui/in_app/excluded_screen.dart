import 'package:flutter/material.dart';

import '../../actions/event_actions.dart';
import '../../actions/log.dart';
import '../../app_graph.dart';
import '../controls/basics.dart';
import '../theme.dart';

/// A plain screen to test in-app message exclusion. Its route name is the
/// screen name the SDK sees.
class ExcludedScreen extends StatelessWidget {
  const ExcludedScreen({super.key});

  static const routeName = 'ExcludedScreen';

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final store = AppGraph.store;
    final excluded = store.excludedScreens.any(
      (s) => s.toLowerCase() == routeName.toLowerCase(),
    );
    final trigger = store.triggerEvent;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    icon: Icon(Icons.arrow_back, color: c.textMuted),
                  ),
                  Text(
                    'Excluded screen',
                    style: AppType.title.copyWith(color: c.text),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'This is $routeName. While it is in the excluded list, in-app messages wait instead of showing here. '
                      'Trigger one below, then go back: it should show on the previous screen.',
                      style: AppType.body.copyWith(color: c.textMuted),
                    ),
                    const SectionHeader('Status'),
                    SettingRow(
                      'This screen',
                      showDivider: false,
                      trailing: [
                        excluded
                            ? const StatusPill('excluded', LogState.ok)
                            : const StatusPill(
                                'not excluded',
                                LogState.warning,
                              ),
                      ],
                    ),
                    if (!excluded)
                      const HelpText(
                        'Add $routeName to Excluded screens on the In-app tab to test exclusion.',
                      ),
                    const SectionHeader('Test'),
                    AppButton(
                      'Trigger $trigger',
                      () => AppGraph.rerun(EventActions.trigger(trigger)),
                      enabled: trigger.trim().isNotEmpty,
                    ),
                    _LatestLog(),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: AppButton(
                        'Back',
                        () => Navigator.of(context).pop(),
                        style: ButtonStyleKind.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestLog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return ListenableBuilder(
      listenable: AppGraph.log,
      builder: (context, _) {
        final latest = AppGraph.log.entries.firstOrNull;
        if (latest == null) return const SizedBox.shrink();
        final text = latest.detail.isEmpty
            ? latest.title
            : '${latest.title} · ${latest.detail}';
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              StatusDot(latest.state),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
