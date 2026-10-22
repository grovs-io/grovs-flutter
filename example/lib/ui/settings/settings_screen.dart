import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../actions/log.dart';
import '../../app_graph.dart';
import '../controls/basics.dart';
import '../help.dart';
import '../theme.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = SettingsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final config = AppGraph.config;
    final baseUrl = config.baseUrl;
    final nativeFile = defaultTargetPlatform == TargetPlatform.iOS
        ? 'Set in Info.plist (Grovs* keys). Change it there and rebuild.'
        : 'Set in AndroidManifest.xml (grovs_* meta-data). Change it there and rebuild.';
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 4, right: 16, bottom: 24),
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
                  const Expanded(child: ScreenTitle('Settings')),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader('Project'),
                    CopyRow(
                      'API key',
                      config.apiKey.isEmpty ? null : config.apiKey,
                      info: Help.apiKey,
                    ),
                    SettingRow(
                      'Environment',
                      info: Help.environment,
                      trailing: [
                        StatusPill(
                          config.useTestEnvironment ? 'Test' : 'Prod',
                          config.useTestEnvironment
                              ? LogState.neutral
                              : LogState.ok,
                        ),
                      ],
                    ),
                    SettingRow(
                      'Base URL',
                      info: Help.baseUrl,
                      trailing: [
                        _Value(
                          baseUrl == null || baseUrl.isEmpty
                              ? 'SDK default'
                              : baseUrl,
                        ),
                      ],
                    ),
                    SettingRow(
                      'Clipboard domains',
                      info: Help.clipboardDomains,
                      trailing: [
                        _Value(
                          config.clipboardDomains.isEmpty
                              ? 'none'
                              : config.clipboardDomains.join(', '),
                        ),
                      ],
                    ),
                    SettingRow(
                      'Auto track screens',
                      info: Help.autoTrackScreens,
                      trailing: const [_Value('GrovsNavigatorObserver')],
                    ),
                    SettingRow(
                      'Start with SDK enabled',
                      info: Help.startEnabled,
                      trailing: [_Value(config.startEnabled ? 'On' : 'Off')],
                    ),
                    HelpText(nativeFile),
                    const SectionHeader('Developer'),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => SettingRow(
                        'Debug level',
                        info: Help.debugLevel,
                        showDivider: false,
                        trailing: [
                          SizedBox(
                            width: 140,
                            child: Segment(
                              debugLevels,
                              _controller.debugLevel,
                              _controller.changeDebugLevel,
                              compact: true,
                              label: (level) =>
                                  level[0].toUpperCase() + level.substring(1),
                            ),
                          ),
                        ],
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

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppType.body.copyWith(color: GrovsColors.of(context).textMuted),
    ),
  );
}
