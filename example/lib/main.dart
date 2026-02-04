import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/config/app_config.dart';
import 'package:example/config/router_config.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DragonflyApp(config: AppConfig()).init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _router = AppRouterConfig();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dragonfly Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: _router.initialRoute,
    );
  }
}
