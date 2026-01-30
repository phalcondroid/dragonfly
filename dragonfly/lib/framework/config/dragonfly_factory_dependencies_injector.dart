import 'package:dragonfly/dragonfly.dart';

class DragonflyFactoryDependenciesInjector {
  final DragonflyContainer di;

  DragonflyFactoryDependenciesInjector({required this.di});

  Future<void> register<T extends Object>(T instance) async {
    if (!di.isRegistered<T>(instance: instance)) {
      di.registerSingleton<T>(instance);
    }
  }
}
