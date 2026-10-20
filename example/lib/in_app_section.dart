import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

const _maxLogEntries = 50;

class InAppSection extends StatefulWidget {
  const InAppSection({super.key});

  @override
  State<InAppSection> createState() => _InAppSectionState();
}

class _InAppSectionState extends State<InAppSection> {
  final _grovs = Grovs();
  final _excludedScreensController = TextEditingController();
  final _log = <String>[];
  StreamSubscription<InAppMessageEvent>? _subscription;
  bool _dismissCurrent = false;
  bool _debugLogging = false;

  @override
  void initState() {
    super.initState();
    _subscription = _grovs.onInAppMessage.listen(
      (event) => _addLog(_describe(event)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _excludedScreensController.dispose();
    super.dispose();
  }

  void _addLog(String entry) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, entry);
      if (_log.length > _maxLogEntries) _log.removeLast();
    });
  }

  String _describe(InAppMessageEvent event) {
    switch (event) {
      case InAppMessageShown():
        return 'shown ${event.campaignId}';
      case InAppMessageClicked():
        return 'clicked ${event.campaignId} button=${event.buttonId} '
            'payload=${event.payload}';
      case InAppMessageDismissed():
        return 'dismissed ${event.campaignId} (${event.reason.name})';
      case InAppMessageAnswered():
        return 'answered ${event.campaignId} value=${event.value} '
            'comment=${event.comment}';
      case InAppMessageFailed():
        return 'failed ${event.campaignId}: ${event.message}';
    }
  }

  Future<void> _run(String action, Future<void> Function() call) async {
    try {
      await call();
      _addLog(action);
    } on GrovsException catch (e) {
      _addLog('$action failed: ${e.message}');
    }
  }

  Future<void> _applyExcludedScreens() {
    final screens = _excludedScreensController.text
        .split(',')
        .map((screen) => screen.trim())
        .where((screen) => screen.isNotEmpty)
        .toList();
    return _run(
      'excluded screens: $screens',
      () => _grovs.setInAppExcludedScreens(screens),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'In-app messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _run('paused', _grovs.pauseInAppMessages),
                  child: const Text('Pause'),
                ),
                ElevatedButton(
                  onPressed: () => _run('resumed', _grovs.resumeInAppMessages),
                  child: const Text('Resume'),
                ),
                ElevatedButton(
                  onPressed: () => _run(
                    'discarded (dismissCurrent=$_dismissCurrent)',
                    () => _grovs.discardInAppMessages(
                      dismissCurrent: _dismissCurrent,
                    ),
                  ),
                  child: const Text('Discard'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dismiss current on discard'),
              value: _dismissCurrent,
              onChanged: (value) => setState(() => _dismissCurrent = value),
            ),
            TextField(
              controller: _excludedScreensController,
              decoration: const InputDecoration(
                labelText: 'Excluded screens (comma separated)',
              ),
              onSubmitted: (_) => _applyExcludedScreens(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _applyExcludedScreens,
              child: const Text('Apply excluded screens'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In-app debug logging'),
              value: _debugLogging,
              onChanged: (value) {
                setState(() => _debugLogging = value);
                _run(
                  'debug logging: $value',
                  () => _grovs.setInAppDebugLogging(value),
                );
              },
            ),
            const Text(
              'Event log',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 160,
              child: _log.isEmpty
                  ? const Text('No events yet', style: TextStyle(fontSize: 12))
                  : ListView.builder(
                      itemCount: _log.length,
                      itemBuilder: (context, index) => Text(
                        _log[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
