import 'package:flutter/material.dart' hide Chip;

import '../../app_graph.dart';
import '../controls/basics.dart';
import '../controls/chips.dart';
import '../controls/fields.dart';
import '../help.dart';
import '../theme.dart';
import 'excluded_screen.dart';

class InAppScreen extends StatelessWidget {
  const InAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inApp = AppGraph.inApp;
    final c = GrovsColors.of(context);
    return ListenableBuilder(
      listenable: inApp,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTitle('In-app'),
            Segment<bool>(
              const [false, true],
              inApp.running,
              inApp.setRunning,
              label: (running) => running ? 'Running' : 'Paused',
            ),
            const SectionHeader('Show a message', info: Help.showMessage),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    value: inApp.trigger,
                    onChanged: inApp.setTrigger,
                    mono: true,
                    onSubmitted: inApp.fireTrigger,
                  ),
                ),
                const SizedBox(width: 6),
                AppButton(
                  'Trigger',
                  inApp.fireTrigger,
                  small: true,
                  enabled: inApp.trigger.trim().isNotEmpty,
                ),
              ],
            ),
            const HelpText(
              'Fires this event. Set a campaign with this trigger in the dashboard.',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ChipRow(
                inApp.triggerSuggestions,
                inApp.trigger,
                inApp.setTrigger,
              ),
            ),
            const SectionHeader('Queue', info: Help.queue),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    'Discard waiting',
                    () => inApp.discard(dismissCurrent: false),
                    style: ButtonStyleKind.outline,
                    small: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    'Close current',
                    () => inApp.discard(dismissCurrent: true),
                    style: ButtonStyleKind.outline,
                    small: true,
                  ),
                ),
              ],
            ),
            const SectionHeader('Rules'),
            SwitchRow(
              'Debug logging',
              inApp.debugLogging,
              inApp.setDebugLogging,
              info: Help.inAppDebug,
            ),
            const SizedBox(height: 10),
            ChipInput(
              values: inApp.excluded,
              onChanged: inApp.setExcluded,
              label: 'Excluded screens',
              info: Help.excludedScreens,
              placeholder: 'Add screen',
            ),
            SettingRow(
              'Open an excluded screen',
              onTap: () =>
                  Navigator.pushNamed(context, ExcludedScreen.routeName),
              showDivider: false,
              trailing: [Icon(Icons.keyboard_arrow_right, color: c.textFaint)],
            ),
          ],
        ),
      ),
    );
  }
}
