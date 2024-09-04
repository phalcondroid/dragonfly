import 'package:get_it/get_it.dart';

typedef DiItemType<T> = Map<String, T>;

enum DragonflyInjectorType { singleton, factory }

class DragonflyInjector {
  static GetIt di = GetIt.instance;

  static void set<T extends Object>(String name, T dependency,
      {DragonflyInjectorType type = DragonflyInjectorType.singleton}) {
    if (type == DragonflyInjectorType.singleton) {
      di.registerSingleton(dependency, instanceName: name);
    }
  }

  static T get<T extends Object>(String name) {
    return di.get<T>(instanceName: name);
  }
}
