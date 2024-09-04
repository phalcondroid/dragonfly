import 'package:dragonfly/core/config/dragonfly_local_storage_config.dart';
import 'package:dragonfly/core/config/dragonfly_network_config.dart';
import 'package:dragonfly/core/network/adapter/dragonfly_network_http_adapter.dart';
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
