import 'package:example/components/characters/presentation/views/character_view.dart';
import 'package:flutter/material.dart';
import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/config/app_config.dart';
import 'package:example/components/characters/config/injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DragonflyApp(config: AppConfig()).init();
  await initDragonflyContainer();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dragonfly Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CharacterViewProvider(),
    );
  }
}
