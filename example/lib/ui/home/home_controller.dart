import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:grovs_flutter_plugin/grovs.dart';

import '../../actions/call_code.dart';
import '../../actions/log.dart';
import '../../app_graph.dart';
import '../../data/forms.dart';
import '../../data/key_value.dart';

/// State of the Home tab: the consent switch and the identity editor.
class HomeController extends ChangeNotifier {
  HomeController() : identity = AppGraph.store.identity {
    draft = identity;
  }

  Identity identity;
  bool editingIdentity = false;
  late Identity draft;

  final _random = Random();
  var _disposed = false;

  String randomIdentifier() => 'qa_${100000 + _random.nextInt(900000)}';

  /// The switch moves at once. If the SDK call fails, it moves back and the
  /// error shows in the log.
  void setSdkEnabled(bool on) {
    AppGraph.sdkEnabled.value = on;
    unawaited(_applySdkEnabled(on));
  }

  Future<void> _applySdkEnabled(bool on) async {
    final outcome = await AppGraph.runner.run(
      TestAction(
        LogType.sdk,
        on ? 'SDK enabled' : 'SDK disabled',
        callCode('setSDK', [('enabled', on)]),
        () async {
          await Grovs().setSDK(on);
          return ActionResult(LogState.ok, on ? 'sending' : 'holding events');
        },
        repeatable: false,
      ),
    );
    final failed = outcome.result.state == LogState.error;
    if (failed && !_disposed && AppGraph.sdkEnabled.value == on) {
      AppGraph.sdkEnabled.value = !on;
    }
  }

  void startEditing() {
    draft = identity;
    editingIdentity = true;
    notifyListeners();
  }

  void cancelEditing() {
    editingIdentity = false;
    notifyListeners();
  }

  void updateDraft(Identity Function(Identity) change) {
    draft = change(draft);
    notifyListeners();
  }

  void saveIdentity() {
    final saved = draft;
    identity = saved;
    AppGraph.store.identity = saved;
    editingIdentity = false;
    notifyListeners();
    final identifier = saved.identifier;
    final attributes = toValueMap(saved.attributes);
    unawaited(
      AppGraph.runner.run(
        TestAction(
          LogType.sdk,
          'Identity saved',
          callCode('identity', [
            ('identifier', identifier),
            ('attributes', attributes),
          ]),
          () async {
            final grovs = Grovs();
            if (identifier != null) await grovs.setUserIdentifier(identifier);
            await grovs.setUserAttributes(attributes);
            return identifier == null
                ? const ActionResult(
                    LogState.warning,
                    'no identifier, the plugin cannot clear an identifier',
                  )
                : ActionResult(LogState.ok, identifier);
          },
          repeatable: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
