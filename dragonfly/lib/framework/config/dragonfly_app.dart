import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/config/dragonfly_config.dart';
import 'package:get_it/get_it.dart';

class DragonflyApp {
  final DragonflyConfig config;
  final List<DragonflyLocalStorageConfig>? itemDbConfig;
  GetIt? internalDependencies;

  DragonflyApp({required this.config, this.itemDbConfig});

  Future<void> init() async {
    List<DragonflyInstanceConfig> instanceConfig = config.instanceConfigs;
    for (DragonflyInstanceConfig config in instanceConfig) {
      config.initConfig();
    }
    await config.injector?.inject!(DragonflyContainer.I);
  }
}
