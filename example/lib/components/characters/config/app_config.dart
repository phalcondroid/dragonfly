import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/config/injector.dart';

import 'app_config.router.dart';

@RouterConfig()
class AppConfig extends DragonflyConfig with $AppConfig {
  /// Unified adapter configs — HTTP + WebSocket.
  ///
  /// Each adapter registers its transport(s) in the DI container during
  /// [DragonflyApp.init]. Custom adapters (WebRTC, gRPC, GraphQL, etc.)
  /// subclass [DragonflyAdapterConfig] and are added to this list.
  @override
  List<DragonflyAdapterConfig> get adapters => [
    DragonflyHttpAdapterConfig(
      connectionName: 'defaultHttpNetwork',
      options: const DragonflyHttpBaseOptions(
        baseUrl: 'https://rickandmortyapi.com/api/',
      ),
    ),
    DragonflyWebSocketAdapterConfig(
      connectionName: 'events',
      config: const DragonflyRealtimeConfig(
        url: 'wss://echo.websocket.org',
      ),
    ),
  ];

  @override
  DragonflyInjector? get injector => DragonflyInjector(
    inject: (DragonflyContainer injector) async {
      await initDragonflyContainer();
    },
  );
}
