import 'package:flutter/material.dart';
import 'package:grovs_flutter_plugin/grovs.dart';

import 'app_graph.dart';
import 'ui/app_scaffold.dart';
import 'ui/in_app/excluded_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicense();
  await AppGraph.init();
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grovs Test',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      navigatorObservers: [Grovs.navigatorObserver],
      home: const AppScaffold(),
      routes: {ExcludedScreen.routeName: (_) => const ExcludedScreen()},
    );
  }
}
