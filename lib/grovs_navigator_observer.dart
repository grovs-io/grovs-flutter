import 'package:flutter/widgets.dart';

import 'grovs.dart';

/// A [NavigatorObserver] that automatically tracks Flutter screen views.
///
/// Add it to your `MaterialApp.navigatorObservers`:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [Grovs.navigatorObserver],
///   // ...
/// );
/// ```
///
/// Screen names resolve in this order:
/// 1. [screenNameExtractor] if provided.
/// 2. The route's `RouteSettings.name` (named routes).
/// 3. A fallback derived from the route's runtime type.
///
/// The resolved name is then translated through the aliases set via
/// `Grovs().setScreenAliases(...)`.
///
/// Note: the route-type fallback (step 3) produces obfuscated names in release
/// builds. Name your routes or supply a [screenNameExtractor] for stable names.
class GrovsNavigatorObserver extends NavigatorObserver {
  GrovsNavigatorObserver({
    String? Function(Route<dynamic> route)? screenNameExtractor,
    Grovs? grovs,
  })  : _screenNameExtractor = screenNameExtractor,
        _grovs = grovs ?? Grovs();

  final String? Function(Route<dynamic> route)? _screenNameExtractor;
  final Grovs _grovs;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _track(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _track(previousRoute);
    }
  }

  void _track(Route<dynamic> route) {
    if (route is! PageRoute) {
      return;
    }
    final rawName = _resolveName(route);
    final aliased = Grovs.screenAliases[rawName] ?? rawName;
    _grovs.trackScreenView(aliased);
  }

  String _resolveName(Route<dynamic> route) {
    final extracted = _screenNameExtractor?.call(route);
    if (extracted != null && extracted.isNotEmpty) {
      return extracted;
    }
    final settingsName = route.settings.name;
    if (settingsName != null && settingsName.isNotEmpty) {
      return settingsName;
    }
    return route.runtimeType.toString();
  }
}
