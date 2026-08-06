import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/config/injector.dart';

import 'app_config.router.dart';

@RouterConfig()
class AppConfig extends DragonflyConfig with $AppConfig {
  /// HTTP instance config
  ///
  ///
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
      // Routing is driven entirely by the generated AppRouterConfig mixin
      // (see main.dart) — there is no runtime router singleton to configure.
    },
  );
}
