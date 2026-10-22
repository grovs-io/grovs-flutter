import 'package:flutter/foundation.dart';
import 'package:grovs_flutter_plugin/grovs.dart';

import '../../actions/call_code.dart';
import '../../actions/log.dart';
import '../../app_graph.dart';

const debugLevels = ['info', 'error'];

class SettingsController extends ChangeNotifier {
  String debugLevel = AppGraph.store.debugLevel;

  Future<void> changeDebugLevel(String level) async {
    debugLevel = level;
    AppGraph.store.debugLevel = level;
    notifyListeners();
    final shown = level.toUpperCase();
    final code = callCode('setDebug', [('level', shown)]);
    try {
      await Grovs().setDebugLevel(level);
      AppGraph.log.add(
        LogType.sdk,
        LogState.ok,
        'Debug level $shown',
        code: code,
      );
    } catch (e) {
      AppGraph.log.add(
        LogType.sdk,
        LogState.error,
        'Debug level $shown failed',
        detail: '$e',
        code: code,
      );
    }
  }
}
