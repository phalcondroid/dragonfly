# Configuration

The `DragonflyConfig` subclass is the single entry point for configuring the
Dragonfly runtime — DI, network adapters, session, and routing.

```dart
class AppConfig extends DragonflyConfig {
  @override
  List<DragonflyAdapterConfig> get adapters => [
    DragonflyHttpAdapterConfig(
      options: const DragonflyHttpBaseOptions(
        baseUrl: 'https://api.example.com/',
        connectTimeout: Duration(seconds: 5),
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
```

> `instanceConfigs` and `realtimeConfigs` are deprecated — use the unified
> `adapters` list instead.

### Custom adapters

Subclass `DragonflyAdapterConfig` to register custom transport adapters (WebRTC,
gRPC, GraphQL, MQTT, etc.):

```dart
class WebRTCAdapterConfig extends DragonflyAdapterConfig {
  final String connectionName;
  const WebRTCAdapterConfig({required this.connectionName});

  @override
  void initConfig(DragonflyContainer container) {
    container.registerSingleton<DragonflyBaseNetworkAdapter>(
      WebRTCAdapter(),
      instanceName: connectionName,
    );
  }
}

// Then add it to the adapters list:
@override
List<DragonflyAdapterConfig> get adapters => [
  DragonflyHttpAdapterConfig(options: ...),
  WebRTCAdapterConfig(connectionName: 'webrtc'),
];
```

The new `DragonflyAuthenticatedAdapter` wraps **any** `DragonflyBaseNetworkAdapter`
to inject session tokens, making authentication transport-agnostic.

An authenticated adapter is registered automatically for every HTTP connection
under `'<name>:authenticated'`. `@Authenticated()` on a repository method resolves it.

> See `docs/topics/adapters.md` for a complete gRPC adapter
> implementation showing the full pattern end-to-end.

[← Back to README.md](../../README.md)
