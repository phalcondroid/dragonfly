import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:flutter/material.dart';
import 'package:example/components/characters/config/user_config.dart';
import 'package:example/components/characters/config/injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure all dependencies (Repository and UseCaseComponent)
  await initDragonflyContainer();

  await DragonflyContainer()
      .get<GetUserListUseCase>()
      .call("Rick", ["1", "2", "3"])
      .then((value) {
        print(
          "===>>>> value: ${value.fold((l) => l.toString(), (r) => r.toString())}",
        );
      });
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

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    DragonflyApp(config: UserConfig()).init();
    /*CharacterRepository().getAll("sss", [""]).then(
      (value) {
        print("===>>>> comming from repo: ${value.results.first.episode}");
      },
    );*/
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
