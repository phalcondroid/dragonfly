import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/config/injector.dart';
import 'package:example/config/router_config.dart';

class AppConfig extends DragonflyConfig {
  @override
  List<DragonflyInstanceConfig> get instanceConfigs => [
    const DragonflyInstanceConfig(
      options: DragonflyHttpBaseOptions(
        baseUrl: "https://rickandmortyapi.com/api/",
      ),
    ),
  ];

  /// Realtime transport backing `CharacterRepository`'s `@Subscribe` methods.
  ///
  /// The connection name must match `@Repository(realtimeConnection: "events")`.
  /// The socket is opened lazily, on the first `listen`, so declaring it here
  /// costs nothing until a stream is actually used.
  @override
  List<DragonflyRealtimeInstanceConfig> get realtimeConfigs => [
    const DragonflyRealtimeInstanceConfig(
      connectionName: "events",
      config: DragonflyRealtimeConfig(
        url: "wss://echo.websocket.org",
      ),
    ),
  ];

  @override
  DragonflyInjector? get injector => DragonflyInjector(
    inject: (DragonflyContainer injector) async {
      await initDragonflyContainer();

      // Initialize Router
      final routerConfig = AppRouterConfig();
      DragonflyRouter.instance.configure(
        routerConfig.routes,
        initialRoute: routerConfig.initialRoute,
      );
    },
  );
}
