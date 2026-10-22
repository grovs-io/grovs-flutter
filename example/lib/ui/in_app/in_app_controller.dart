import 'package:flutter/foundation.dart';
import 'package:grovs_flutter_plugin/grovs.dart';

import '../../actions/call_code.dart';
import '../../actions/event_actions.dart';
import '../../actions/log.dart';
import '../../app_graph.dart';
import '../../data/settings_store.dart';

const _defaultTriggers = ['demo_tapped', 'onboarding_done', 'promo_seen'];

/// State of the In-app tab. One shared instance (`AppGraph.inApp`).
class InAppController extends ChangeNotifier {
  InAppController()
    : trigger = AppGraph.store.triggerEvent,
      debugLogging = AppGraph.store.inAppDebug,
      excluded = AppGraph.store.excludedScreens {
    triggerSuggestions = _triggerNames();
  }

  bool running = true;
  String trigger;
  bool debugLogging;
  List<String> excluded;
  late List<String> triggerSuggestions;

  void setTrigger(String value) {
    trigger = value;
    notifyListeners();
  }

  void setRunning(bool on) {
    running = on;
    notifyListeners();
    AppGraph.rerun(
      TestAction(
        LogType.inApp,
        on ? 'Resume messages' : 'Pause messages',
        callCode(on ? 'resumeInAppMessages' : 'pauseInAppMessages'),
        () async {
          on
              ? await Grovs().resumeInAppMessages()
              : await Grovs().pauseInAppMessages();
          return ActionResult(LogState.ok, on ? 'running' : 'paused');
        },
        repeatable: false,
      ),
    );
  }

  void fireTrigger() {
    if (trigger.trim().isEmpty) return;
    final store = AppGraph.store;
    store.triggerEvent = trigger;
    store.remember(recentTriggers, trigger);
    triggerSuggestions = _triggerNames();
    notifyListeners();
    AppGraph.rerun(EventActions.trigger(trigger));
  }

  /// Discarding also leaves the SDK paused.
  void discard({required bool dismissCurrent}) {
    running = false;
    notifyListeners();
    AppGraph.rerun(
      TestAction(
        LogType.inApp,
        dismissCurrent ? 'Close current message' : 'Discard waiting messages',
        callCode('discardInAppMessages', [('dismissCurrent', dismissCurrent)]),
        () async {
          await Grovs().discardInAppMessages(dismissCurrent: dismissCurrent);
          return const ActionResult(LogState.ok, 'paused');
        },
      ),
    );
  }

  void setDebugLogging(bool on) {
    debugLogging = on;
    AppGraph.store.inAppDebug = on;
    notifyListeners();
    AppGraph.rerun(
      TestAction(
        LogType.inApp,
        'Debug logging ${on ? 'on' : 'off'}',
        callCode('setInAppDebugLogging', [('enabled', on)]),
        () async {
          await Grovs().setInAppDebugLogging(on);
          return const ActionResult(LogState.ok, 'applied');
        },
        repeatable: false,
      ),
    );
  }

  void setExcluded(List<String> screens) {
    excluded = screens;
    AppGraph.store.excludedScreens = screens;
    notifyListeners();
    AppGraph.rerun(
      TestAction(
        LogType.inApp,
        'Excluded screens set',
        callCode('setInAppExcludedScreens', [('screens', screens)]),
        () async {
          await Grovs().setInAppExcludedScreens(screens);
          return ActionResult(
            LogState.ok,
            screens.isEmpty ? 'none' : screens.join(', '),
          );
        },
        repeatable: false,
      ),
    );
  }

  List<String> _triggerNames() =>
      {...AppGraph.store.recent(recentTriggers), ..._defaultTriggers}.toList();
}
