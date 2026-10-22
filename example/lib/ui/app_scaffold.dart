import 'package:flutter/material.dart';

import '../actions/log.dart';
import '../app_graph.dart';
import '../data/strings.dart';
import 'controls/basics.dart';
import 'controls/sheet.dart';
import 'logs/logs_panel.dart';
import 'tab_icons.dart';
import 'theme.dart';

enum AppTab {
  home('Home', TabIcon.home),
  links('Links', TabIcon.links),
  events('Events', TabIcon.events),
  inApp('In-app', TabIcon.inApp);

  const AppTab(this.title, this.icon);
  final String title;
  final Path Function() icon;
}

const _transition = Duration(milliseconds: 260);

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold>
    with SingleTickerProviderStateMixin {
  var _tab = AppTab.home;
  var _direction = 1;
  var _panelShown = false;
  final _logFilter = ValueNotifier(LogFilter.all);
  late final _tabChange = AnimationController(
    vsync: this,
    duration: _transition,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    AppGraph.panel.addListener(_onPanel);
  }

  @override
  void dispose() {
    AppGraph.panel.removeListener(_onPanel);
    _tabChange.dispose();
    _logFilter.dispose();
    super.dispose();
  }

  void _onPanel() {
    final panel = AppGraph.panel.value;
    if (!panel.open || _panelShown || !mounted) return;
    _panelShown = true;
    showAppSheet(
      context,
      heightFraction: 0.82,
      builder: (_) => LogsPanel(filter: _logFilter, entryId: panel.entryId),
    ).whenComplete(() {
      _panelShown = false;
      AppGraph.closePanel();
    });
  }

  void _select(AppTab tab) {
    if (tab == _tab) return;
    setState(() {
      _direction = tab.index > _tab.index ? 1 : -1;
      _tab = tab;
    });
    _tabChange.forward(from: 0);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'Settings'),
        builder: (_) => const _SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    // The keyboard covers the strip and tab bar, so they step aside while typing.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: _TabTransition(
                animation: _tabChange,
                direction: _direction,
                child: IndexedStack(
                  index: _tab.index,
                  children: [for (final tab in AppTab.values) _tabBody(tab)],
                ),
              ),
            ),
          ),
          if (!typing) ...[const _ConsoleStrip(), _TabBar(_tab, _select)],
        ],
      ),
    );
  }

  Widget _tabBody(AppTab tab) => switch (tab) {
    AppTab.home => _Placeholder(
      'Grovs Test',
      trailing: IconButton(
        onPressed: _openSettings,
        tooltip: 'Settings',
        icon: Icon(
          Icons.settings_outlined,
          color: GrovsColors.of(context).textMuted,
        ),
      ),
    ),
    _ => _Placeholder(tab.title),
  };
}

/// The new tab fades in with a short slide from the side it was picked on.
class _TabTransition extends StatelessWidget {
  const _TabTransition({
    required this.animation,
    required this.direction,
    required this.child,
  });

  final Animation<double> animation;
  final int direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final slide = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
    );
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(60 / 260, 1),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween(
          begin: Offset(direction / 12, 0),
          end: Offset.zero,
        ).animate(slide),
        child: child,
      ),
    );
  }
}

class _ConsoleStrip extends StatelessWidget {
  const _ConsoleStrip();

  void _open() {
    if (!AppGraph.panel.value.open) AppGraph.openPanel();
  }

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return ListenableBuilder(
      listenable: AppGraph.log,
      builder: (context, _) {
        final latest = AppGraph.log.entries.firstOrNull;
        final state = AppGraph.log.unseenError
            ? LogState.error
            : latest?.state ?? LogState.neutral;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _open,
          onVerticalDragUpdate: (d) {
            if (d.delta.dy < -8) _open();
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                StatusDot(state),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latest?.title ?? 'No events yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption.copyWith(color: c.text),
                  ),
                ),
                if (latest != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    formatClock(latest.time),
                    style: AppType.caption.copyWith(color: c.textFaint),
                  ),
                ],
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Open logs',
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 16,
                    color: c.textFaint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar(this.selected, this.onSelect);

  final AppTab selected;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: c.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: c.chipFill,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? c.text
                  : c.textMuted,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => AppType.label.copyWith(
              color: states.contains(WidgetState.selected)
                  ? c.text
                  : c.textMuted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selected.index,
          onDestinationSelected: (i) => onSelect(AppTab.values[i]),
          destinations: [
            for (final tab in AppTab.values)
              NavigationDestination(icon: TabIcon(tab.icon), label: tab.title),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: ScreenTitle(title)),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 4, right: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}
