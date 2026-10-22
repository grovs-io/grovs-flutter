import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter/services.dart';

import '../../actions/log.dart';
import '../../app_graph.dart';
import '../../data/key_value.dart';
import '../../data/link_tools.dart';
import '../../data/strings.dart';
import '../../push.dart';
import '../controls/basics.dart';
import '../controls/chips.dart';
import '../controls/fields.dart';
import '../controls/key_value_rows.dart';
import '../controls/sheet.dart';
import '../events/event_forms.dart';
import '../help.dart';
import '../links/link_form_fields.dart';
import '../links/open_link.dart';
import '../theme.dart';
import 'home_controller.dart';

bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final home = AppGraph.home;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(onOpenSettings),
          _StatusSection(home, onOpenSettings),
          const _OpenedFromSection(),
          ListenableBuilder(
            listenable: home,
            builder: (_, _) => _IdentitySection(home),
          ),
          const _QuickActions(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.onOpenSettings);

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final environment = AppGraph.config.useTestEnvironment ? 'Test' : 'Prod';
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'g',
              style: AppType.label.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Grovs Test',
              style: AppType.title.copyWith(color: c.text),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$environment · $pluginVersion',
            style: AppType.caption.copyWith(color: c.textMuted),
          ),
          IconButton(
            onPressed: onOpenSettings,
            tooltip: 'Settings',
            icon: Icon(Icons.settings_outlined, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatefulWidget {
  const _StatusSection(this.home, this.onOpenSettings);

  final HomeController home;
  final VoidCallback onOpenSettings;

  @override
  State<_StatusSection> createState() => _StatusSectionState();
}

class _StatusSectionState extends State<_StatusSection> {
  late final AppLifecycleListener _lifecycle;
  var _askedOnAndroid = false;

  @override
  void initState() {
    super.initState();
    // Permission can change in system settings while the app is in the background.
    _lifecycle = AppLifecycleListener(onResume: Push.refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    await Push.requestPermission();
    if (!mounted || _isIos) return;
    setState(() => _askedOnAndroid = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final config = AppGraph.config;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Status'),
        ValueListenableBuilder(
          valueListenable: AppGraph.sdkEnabled,
          builder: (_, enabled, _) => SwitchRow(
            'SDK enabled',
            enabled,
            widget.home.setSdkEnabled,
            info: Help.sdkEnabled,
          ),
        ),
        SettingRow(
          'Project',
          onTap: widget.onOpenSettings,
          trailing: [
            Text(
              '${config.useTestEnvironment ? 'test' : 'prod'} · '
              '${middleEllipsis(config.apiKey)}',
              style: AppType.body.copyWith(color: c.textMuted),
            ),
            Icon(Icons.keyboard_arrow_right, color: c.textFaint),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: Push.status,
          builder: (_, status, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingRow(
                'Notifications',
                trailing: switch (status) {
                  NotificationStatus.unknown => const [],
                  NotificationStatus.allowed => const [
                    StatusPill('Allowed', LogState.ok),
                  ],
                  NotificationStatus.notAllowed => [
                    const StatusPill('Not allowed', LogState.warning),
                    TextAction('Allow', _allow),
                  ],
                  NotificationStatus.notConfigured => const [
                    StatusPill('Not configured', LogState.neutral),
                  ],
                },
              ),
              if (_askedOnAndroid && status == NotificationStatus.notAllowed)
                const HelpText('Turn on notifications in system settings'),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: AppGraph.pushToken,
          builder: (_, token, _) => CopyRow(
            _isIos ? 'APNs token' : 'Push token',
            token,
            emptyText: 'Waiting…',
            info: Help.pushToken,
          ),
        ),
      ],
    );
  }
}

class _OpenedFromSection extends StatefulWidget {
  const _OpenedFromSection();

  @override
  State<_OpenedFromSection> createState() => _OpenedFromSectionState();
}

class _OpenedFromSectionState extends State<_OpenedFromSection> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return ListenableBuilder(
      listenable: AppGraph.log,
      builder: (context, _) {
        final latest = AppGraph.log.entries
            .where((e) => e.type == LogType.link)
            .firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              'Opened from',
              info: Help.openedFrom,
              trailing: latest == null
                  ? null
                  : relativeTime(DateTime.now().difference(latest.time)),
            ),
            if (latest == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Not opened from a link yet',
                  style: AppType.caption.copyWith(color: c.textMuted),
                ),
              )
            else
              SettingRow(
                latest.link ?? 'no link',
                onTap: () => AppGraph.openPanel(latest.id),
                trailing: const [StatusPill('received', LogState.ok)],
              ),
          ],
        );
      },
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection(this.home);

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final header = SectionHeader(
      'Identity',
      info: Help.identity,
      action: home.editingIdentity ? null : 'Change',
      onAction: home.startEditing,
    );
    if (!home.editingIdentity) {
      final identity = home.identity;
      final attributes = summary(identity.attributes);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SettingRow(
            'Identifier',
            onTap: home.startEditing,
            trailing: [
              Flexible(
                child: Text(
                  identity.identifier ?? 'None',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
          SettingRow(
            'Attributes',
            onTap: home.startEditing,
            trailing: [
              Flexible(
                child: Text(
                  attributes.isEmpty ? 'none' : attributes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final draft = home.draft;
    final deviceName = AppGraph.store.deviceName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SuggestField(
          value: draft.identifier ?? '',
          onChanged: (v) => home.updateDraft(
            (i) => v.isEmpty
                ? i.copyWith(clearIdentifier: true)
                : i.copyWith(identifier: v),
          ),
          suggestions: const [],
          label: 'Identifier',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 6,
              children: [
                for (final value in [deviceName, 'qa_user_1'])
                  Chip(
                    value == deviceName ? 'Device name' : value,
                    () =>
                        home.updateDraft((i) => i.copyWith(identifier: value)),
                    selected: draft.identifier == value,
                  ),
                Chip(
                  'Random id',
                  () => home.updateDraft(
                    (i) => i.copyWith(identifier: home.randomIdentifier()),
                  ),
                ),
                Chip(
                  'None',
                  () => home.updateDraft(
                    (i) => i.copyWith(clearIdentifier: true),
                  ),
                  selected: draft.identifier == null,
                  dashed: draft.identifier != null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        KeyValueRows(
          rows: draft.attributes,
          onChanged: (v) => home.updateDraft((i) => i.copyWith(attributes: v)),
          label: 'Attributes',
          suggestedKeys: const ['plan', 'country'],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: AppButton(
                  'Cancel',
                  home.cancelEditing,
                  style: ButtonStyleKind.outline,
                ),
              ),
              Expanded(child: AppButton('Save', home.saveIdentity)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  Future<void> _openClipboard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || !isWebUrl(text)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Clipboard has no link'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (context.mounted) await openLinkInApp(context, text);
  }

  void _showForm(
    BuildContext context,
    Listenable listenable,
    String title,
    Widget Function() fields,
    String action,
    bool Function() enabled,
    VoidCallback run,
  ) {
    showAppSheet(
      context,
      builder: (sheet) => ListenableBuilder(
        listenable: listenable,
        builder: (_, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: AppType.heading.copyWith(
                  color: GrovsColors.of(sheet).text,
                ),
              ),
            ),
            fields(),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppButton(action, () {
                run();
                Navigator.of(sheet).pop();
              }, enabled: enabled()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = AppGraph.links;
    final events = AppGraph.events;
    return ListenableBuilder(
      listenable: Listenable.merge([links, events]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            'Quick actions',
            trailing: 'hold to edit',
            info: Help.quickActions,
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: AppButton(
                  'Generate link',
                  links.generate,
                  enabled: !links.running,
                  onLongPress: () => _showForm(
                    context,
                    links,
                    'Generate link',
                    () => LinkFormFields(links.form, links.update),
                    'Save and generate',
                    () => !links.running,
                    links.generate,
                  ),
                ),
              ),
              Expanded(
                child: AppButton(
                  'Open clipboard',
                  () => _openClipboard(context),
                  style: ButtonStyleKind.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: AppButton(
                  'Track ${events.event.name}',
                  events.trackEvent,
                  style: ButtonStyleKind.outline,
                  enabled: events.eventError == null,
                  onLongPress: () => _showForm(
                    context,
                    events,
                    'Track event',
                    () => EventFormFields(
                      form: events.event,
                      update: events.updateEvent,
                      suggestions: events.eventSuggestions,
                      error: events.eventError,
                      onTrack: events.trackEvent,
                    ),
                    'Save and track',
                    () => events.eventError == null,
                    events.trackEvent,
                  ),
                ),
              ),
              Expanded(
                child: AppButton(
                  events.purchase.label(),
                  events.logPurchase,
                  style: ButtonStyleKind.outline,
                  enabled: events.purchase.isValid(),
                  onLongPress: () => _showForm(
                    context,
                    events,
                    'Purchase',
                    () => PurchaseFormFields(
                      form: events.purchase,
                      update: events.updatePurchase,
                    ),
                    'Save and log',
                    () => events.purchase.isValid(),
                    events.logPurchase,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
