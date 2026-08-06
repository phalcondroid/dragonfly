import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/config/app_config.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig();
  await DragonflyApp(config: config).init();

  runApp(MyApp(config: config));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dragonfly Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: config.onGenerateRoute,
      initialRoute: config.initialRoute,
    );
  }
}
