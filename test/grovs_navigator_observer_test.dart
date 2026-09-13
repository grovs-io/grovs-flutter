import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/grovs_navigator_observer.dart';
import 'package:grovs_flutter_plugin/grovs_platform_interface.dart';
import 'package:grovs_flutter_plugin/grovs_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Records every screen name passed to trackScreenView.
class RecordingGrovsPlatform
    with MockPlatformInterfaceMixin
    implements GrovsPlatform {
  final List<String> screenViews = <String>[];

  @override
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    screenViews.add(screenName);
  }

  // Called by Grovs.setScreenAliases (backend sync); a no-op for these tests.
  @override
  Future<void> setScreenAliases(Map<String, String> aliases) async {}

  // Unused members throw — the observer only calls trackScreenView.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PageRoute<dynamic> _pageRoute({String? name}) {
  return PageRouteBuilder<dynamic>(
    settings: RouteSettings(name: name),
    pageBuilder: (_, __, ___) => const SizedBox(),
  );
}

/// A non-PageRoute route used to verify these are skipped.
class _NonPageRoute extends PopupRoute<dynamic> {
  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => null;
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      const SizedBox();
  @override
  Duration get transitionDuration => Duration.zero;
}

void main() {
  late RecordingGrovsPlatform platform;

  setUp(() {
    platform = RecordingGrovsPlatform();
    GrovsPlatform.instance = platform;
  });

  tearDown(() async {
    // Reset the process-global alias store so it doesn't leak into later
    // tests. This goes through the test's RecordingGrovsPlatform (a no-op)
    // rather than the real MethodChannelGrovs, since it runs before the
    // instance is restored below.
    await Grovs().setScreenAliases({});
    GrovsPlatform.instance = MethodChannelGrovs();
  });

  test('didPush tracks named route by its name', () {
    final observer = GrovsNavigatorObserver();
    observer.didPush(_pageRoute(name: '/home'), null);
    expect(platform.screenViews, ['/home']);
  });

  test('didPush falls back to route type for unnamed route', () {
    final observer = GrovsNavigatorObserver();
    observer.didPush(_pageRoute(name: null), null);
    expect(platform.screenViews.length, 1);
    expect(platform.screenViews.first, contains('PageRouteBuilder'));
  });

  test('screenNameExtractor overrides name resolution', () {
    final observer = GrovsNavigatorObserver(
      screenNameExtractor: (route) => 'CustomName',
    );
    observer.didPush(_pageRoute(name: '/home'), null);
    expect(platform.screenViews, ['CustomName']);
  });

  test('non-PageRoute transitions are skipped', () {
    final observer = GrovsNavigatorObserver();
    observer.didPush(_NonPageRoute(), null);
    expect(platform.screenViews, isEmpty);
  });

  test('didReplace tracks the new route', () {
    final observer = GrovsNavigatorObserver();
    observer.didReplace(
      newRoute: _pageRoute(name: '/cart'),
      oldRoute: _pageRoute(name: '/home'),
    );
    expect(platform.screenViews, ['/cart']);
  });

  test('didPop tracks the route returned to', () {
    final observer = GrovsNavigatorObserver();
    observer.didPop(_pageRoute(name: '/detail'), _pageRoute(name: '/home'));
    expect(platform.screenViews, ['/home']);
  });

  test('aliases are applied to the resolved name', () async {
    await Grovs().setScreenAliases({'/home': 'Home'});
    final observer = GrovsNavigatorObserver();
    observer.didPush(_pageRoute(name: '/home'), null);
    expect(platform.screenViews, ['Home']);
  });

  test(
      'screenNameExtractor returning an empty string falls through to '
      'route.settings.name', () {
    final observer = GrovsNavigatorObserver(
      screenNameExtractor: (route) => '',
    );
    observer.didPush(_pageRoute(name: '/home'), null);
    expect(platform.screenViews, ['/home']);
  });

  test(
      'empty route.settings.name falls through to the runtime-type '
      'fallback', () {
    final observer = GrovsNavigatorObserver();
    observer.didPush(_pageRoute(name: ''), null);
    expect(platform.screenViews.length, 1);
    expect(platform.screenViews.first, contains('PageRouteBuilder'));
  });
}
