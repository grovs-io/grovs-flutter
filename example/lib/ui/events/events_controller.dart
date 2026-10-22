import 'package:flutter/foundation.dart';

import '../../actions/event_actions.dart';
import '../../app_graph.dart';
import '../../data/event_rules.dart';
import '../../data/forms.dart';
import '../../data/key_value.dart';
import '../../data/settings_store.dart';

const _defaultEventNames = ['demo_tapped', 'signup', 'level_up', 'share'];
const _defaultScreenNames = ['Home', 'Paywall', 'Settings', 'Checkout'];

/// State of the Events tab. One shared instance (`AppGraph.events`) so Home
/// can reuse the same forms.
class EventsController extends ChangeNotifier {
  EventsController()
    : event = AppGraph.store.eventForm,
      screen = AppGraph.store.screenForm,
      purchase = AppGraph.store.purchaseForm,
      globalTags = AppGraph.store.globalTags,
      aliases = AppGraph.store.screenAliases {
    eventSuggestions = _names(recentEvents, _defaultEventNames);
    screenSuggestions = _names(recentScreens, _defaultScreenNames);
  }

  EventForm event;
  ScreenForm screen;
  PurchaseForm purchase;
  List<String> globalTags;
  List<KeyValue> aliases;
  late List<String> eventSuggestions;
  late List<String> screenSuggestions;

  String? get eventError => eventNameError(event.name) ?? tagsError(event.tags);

  void updateEvent(EventForm Function(EventForm) change) {
    event = change(event);
    notifyListeners();
  }

  void updateScreen(ScreenForm Function(ScreenForm) change) {
    screen = change(screen);
    notifyListeners();
  }

  void updatePurchase(PurchaseForm Function(PurchaseForm) change) {
    purchase = change(purchase);
    notifyListeners();
  }

  Future<void> trackEvent({bool force = false}) async {
    final error = eventError;
    if (!force && error != null) return;
    final store = AppGraph.store;
    store.eventForm = event;
    store.remember(recentEvents, event.name);
    eventSuggestions = _names(recentEvents, _defaultEventNames);
    notifyListeners();
    await AppGraph.runner.run(
      EventActions.track(event, expectRejected: force && error != null),
    );
  }

  Future<void> trackScreen() async {
    if (screen.name.trim().isEmpty) return;
    final store = AppGraph.store;
    store.screenForm = screen;
    store.remember(recentScreens, screen.name);
    screenSuggestions = _names(recentScreens, _defaultScreenNames);
    notifyListeners();
    await AppGraph.runner.run(EventActions.screen(screen));
  }

  Future<void> logPurchase() async {
    final action = EventActions.purchase(purchase, DateTime.now());
    if (action == null) return;
    AppGraph.store.purchaseForm = purchase;
    await AppGraph.runner.run(action);
  }

  Future<void> logStorePurchase() async {
    if (purchase.storeId.trim().isEmpty) return;
    AppGraph.store.purchaseForm = purchase;
    await AppGraph.runner.run(EventActions.storePurchase(purchase.storeId));
  }

  Future<void> applyGlobalTags(List<String> tags) async {
    globalTags = tags;
    AppGraph.store.globalTags = tags;
    notifyListeners();
    await AppGraph.runner.run(EventActions.globalTags(tags));
  }

  Future<void> applyAliases(List<KeyValue> rows) async {
    aliases = rows;
    AppGraph.store.screenAliases = rows;
    notifyListeners();
    await AppGraph.runner.run(EventActions.aliases(rows));
  }

  List<String> _names(String field, List<String> defaults) =>
      {...AppGraph.store.recent(field), ...defaults}.toList();
}
