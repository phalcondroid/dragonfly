import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/data/repositories/character_repository.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:example/components/characters/presentation/viewmodel/character_bloc.dart';
import 'package:example/components/characters/presentation/views/character_view.dart';
import 'package:flutter/material.dart';
import 'package:example/components/characters/config/app_config.dart';
import 'package:example/components/characters/config/injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DragonflyApp(config: AppConfig()).init();
  // Configure all dependencies (Repository and UseCaseComponent)
  await initDragonflyContainer();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() async {
    setState(() {
      _counter++;
    });

    await DragonflyContainer.I
        .get<GetUserListUseCase>()
        .call("Rick", ["1", "2", "3"])
        .then((value) {
          print(
            "===>>>> value: ${value.fold((l) => l.toString(), (r) => r.toString())}",
          );
        })
        .catchError((e) {
          print("===>>>> error: $e");
        });
  }

  @override
  Widget build(BuildContext context) {
    return DragonflyBlocProvider<CharacterBloc>(
      create: (context) => CharacterBloc(CharacterRepository()),
      child: const CharacterView(),
    );
  }
}
