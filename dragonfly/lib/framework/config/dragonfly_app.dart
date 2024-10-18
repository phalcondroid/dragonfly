import 'package:dragonfly/dragonfly.dart';
import 'package:get_it/get_it.dart';

class DragonflyApp {
  final List<DragonflyNetworkConfig>? itemNetworkConfig;
  final List<DragonflyLocalStorageConfig>? itemDbConfig;
  GetIt? internalDependencies;

  DragonflyApp({this.itemNetworkConfig, this.itemDbConfig});

  Future<void> init() async {
    if (itemNetworkConfig != null) {
      itemNetworkConfig?.forEach((DragonflyNetworkConfig config) {
        DragonflyInjector.set<DragonflyNetworkHttpAdapter>(
            config.identify, DragonflyNetworkHttpAdapter(config: config));
      });
    }
  }
}
