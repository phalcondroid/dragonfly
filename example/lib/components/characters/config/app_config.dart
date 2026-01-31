import 'package:dragonfly/framework/config/dragonfly_config.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';

class AppConfig extends DragonflyConfig {
  @override
  List<DragonflyInstanceConfig> get instanceConfigs => [
    const DragonflyInstanceConfig(
      options: DragonflyHttpBaseOptions(
        baseUrl: "https://rickandmortyapi.com/api/",
      ),
    ),
  ];

  @override
  DragonflyInjector? get injector => DragonflyInjector(
    inject: (DragonflyContainer injector) async {
      print("===>>>> AppConfig Injector called");
      injector.debugPrintRegisteredInstances();
    },
  );
}
