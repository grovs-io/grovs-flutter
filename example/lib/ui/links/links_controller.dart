import 'package:flutter/foundation.dart';

import '../../actions/link_actions.dart';
import '../../actions/log.dart';
import '../../app_graph.dart';
import '../../data/forms.dart';
import '../../data/link_tools.dart';

class LinkResult {
  const LinkResult({required this.ok, this.link, required this.message});

  final bool ok;
  final String? link;
  final String message;
}

/// State of the Links tab. One shared instance (`AppGraph.links`) because
/// Home and the logs panel inspect links too.
class LinksController extends ChangeNotifier {
  LinksController() : form = AppGraph.store.linkForm;

  LinkForm form;
  String inspectInput = '';
  LinkResult? result;
  bool running = false;

  TestAction? _lastAction;
  var _disposed = false;

  void update(LinkForm Function(LinkForm) change) {
    form = change(form);
    notifyListeners();
  }

  void setInspectInput(String value) {
    inspectInput = value;
    notifyListeners();
  }

  void reset() {
    form = const LinkForm();
    AppGraph.store.linkForm = form;
    notifyListeners();
  }

  Future<void> generate() {
    AppGraph.store.linkForm = form;
    return _run(LinkActions.generate(form));
  }

  Future<void> runAgain() async {
    final action = _lastAction;
    if (action != null) await _run(action);
  }

  Future<void> inspect([String? input]) async {
    final path = extractLinkPath(input ?? inspectInput);
    if (path == null) return;
    final outcome = await AppGraph.runner.run(LinkActions.details(path));
    AppGraph.openPanel(outcome.entry.id);
  }

  Future<void> _run(TestAction action) async {
    _lastAction = action;
    running = true;
    notifyListeners();
    final outcome = await AppGraph.runner.run(action);
    final ok = outcome.result.state == LogState.ok;
    result = LinkResult(
      ok: ok,
      link: outcome.result.value,
      message: ok
          ? '${outcome.elapsed.inMilliseconds} ms · ${outcome.result.detail}'
          : '${outcome.error ?? outcome.result.detail}',
    );
    running = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
