import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/config/dragonfly_config.dart';

class DragonflyApp {
  final DragonflyConfig config;
  final List<DragonflyLocalStorageConfig>? itemDbConfig;

  DragonflyApp({required this.config, this.itemDbConfig});

  Future<void> init() async {
    List<DragonflyInstanceConfig> instanceConfig = config.instanceConfigs;
    for (DragonflyInstanceConfig config in instanceConfig) {
      config.initConfig();
    }
    await config.injector?.inject!(DragonflyContainer.I);
  }
}
