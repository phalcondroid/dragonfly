# Network Adapters

Dragonfly's network layer follows an ORM-dialect pattern — a common interface with
pluggable implementations. The abstract contract is `DragonflyBaseNetworkAdapter`,
which defines `requestObject`, `requestList`, `callForList`, `callForObject`, plus
hooks (`beforeRequest`, `afterResponse`, `buildHeaders`) and lifecycle methods
(`connect`, `disconnect`).

**Built-in adapters:**
- `DragonflyNetworkHttpAdapter` — HTTP transport
- `DragonflyWebSocketAdapter` — WebSocket transport (implements `DragonflyRealtimeAdapter`)

**Community / custom adapters** can be registered by subclassing `DragonflyAdapterConfig`
and adding instances to the `adapters` list on your `DragonflyConfig` subclass. The
framework supports any protocol — WebRTC, gRPC, GraphQL, MQTT, etc.

**Authentication** is transport-agnostic. `DragonflyAuthenticatedAdapter` wraps any
`DragonflyBaseNetworkAdapter` to inject session tokens. An authenticated variant is
registered automatically for every connection under `'<name>:authenticated'`.
`@Authenticated()` on a repository method resolves it.

---

# Custom adapter example — gRPC

This is a complete, production-pattern example of adding a custom transport
adapter to Dragonfly using gRPC. It follows the same architecture as the
built-in HTTP and WebSocket adapters (ORM-dialect pattern).

## Package structure

```
dragonfly_grpc/              ← external pub.dev package (community)
├── pubspec.yaml
├── lib/
│   ├── dragonfly_grpc.dart           ← barrel
│   ├── dragonfly_grpc_adapter.dart   ← implements DragonflyBaseNetworkAdapter
│   ├── dragonfly_grpc_config.dart    ← extends DragonflyAdapterConfig
│   └── proto/                        ← generated protobuf stubs
│       └── example.proto.dart
└── example/
    └── lib/
        └── components/
            └── users/
                ├── config/
                │   └── app_config.dart
                └── data/
                    └── repositories/
                        └── user_grpc_repository.dart
```

---

## 1. Package definition (`pubspec.yaml`)

```yaml
name: dragonfly_grpc
description: "gRPC adapter for the Dragonfly framework."
version: 0.0.1
homepage: https://github.com/nodelorien/dragonfly_grpc

environment:
  sdk: ^3.8.0

dependencies:
  dragonfly: ^0.0.1
  grpc: ^4.0.0
  protobuf: ^3.1.0
```

---

## 2. The adapter — `dragonfly_grpc_adapter.dart`

This is the core of the package. It implements `DragonflyBaseNetworkAdapter`,
translating between the framework's JSON-map protocol and gRPC's protobuf
wire format.

```dart
import 'dart:convert';

import 'package:dragonfly/dragonfly.dart';
import 'package:grpc/grpc.dart';

import 'proto/example.proto.dart';

/// gRPC transport adapter for Dragonfly.
///
/// Implements [DragonflyBaseNetworkAdapter] so generated repositories can
/// resolve it from the DI container and call `requestObject`/`requestList`.
///
/// Also implements [DragonflyRealtimeAdapter] for server-streaming gRPC
/// methods — generated `@Subscribe` methods resolve it by realtime connection
/// name.
///
/// ### How it works
///
/// gRPC methods are mapped from the HTTP method + path convention:
/// - GET `users/{id}` → `userClient.getUser(GetUserRequest(id: id))`
/// - POST `users`     → `userClient.createUser(CreateUserRequest(...))`
/// - Stream `events`  → `eventClient.subscribe(SubscribeRequest(channel: ...))`
///
/// Protobuf messages serialize to `Map<String, Object?>` via `jsonEncode` /
/// `jsonDecode` so the repository generator's `.map(fromJson)` pipeline
/// works unchanged.
class DragonflyGrpcAdapter
    implements DragonflyBaseNetworkAdapter, DragonflyRealtimeAdapter {
  DragonflyGrpcAdapter({
    required this.baseUrl,
    this.enableLogging = true,
    ClientChannel? channel,
  }) : _channel = channel ?? ClientChannel(
          baseUrl,
          options: const ChannelOptions(
            credentials: ChannelCredentials.insecure(),
          ),
        ) {
    _userClient = UserServiceClient(_channel);
    _eventClient = EventServiceClient(_channel);
  }

  final String baseUrl;
  final bool enableLogging;

  final ClientChannel _channel;
  late final UserServiceClient _userClient;
  late final EventServiceClient _eventClient;

  DragonflyLogManager get _log => DragonflyLogManager.instance;

  // ── DragonflyRealtimeAdapter ──────────────────────────────────────────────

  @override
  DragonflyRealtimeState get state => _state;
  DragonflyRealtimeState _state = DragonflyRealtimeState.disconnected;

  @override
  Stream<DragonflyRealtimeState> get stateStream => _stateController.stream;
  final _stateController =
      StreamController<DragonflyRealtimeState>.broadcast();

  @override
  Future<void> connect() async {
    if (_state == DragonflyRealtimeState.connected) return;
    _setState(DragonflyRealtimeState.connecting);
    try {
      await _channel.getConnection();
      _setState(DragonflyRealtimeState.connected);
      _log.success('gRPC connected: $baseUrl',
          source: 'DragonflyGrpcAdapter');
    } catch (e) {
      _setState(DragonflyRealtimeState.disconnected);
      _log.error('gRPC connection failed',
          error: e, source: 'DragonflyGrpcAdapter');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _channel.shutdown();
    _setState(DragonflyRealtimeState.closed);
  }

  void _setState(DragonflyRealtimeState next) {
    if (_state == next) return;
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  // ── DragonflyBaseNetworkAdapter — hooks ──────────────────────────────────

  @override
  Future<void> beforeRequest() async {}

  @override
  Future<void> afterResponse(covariant dynamic response) async {}

  @override
  Map<String, String> buildHeaders(Map<String, String>? headers) {
    final merged = <String, String>{
      'Content-Type': 'application/grpc+proto',
    };
    if (headers != null) merged.addAll(headers);
    return merged;
  }

  // ── DragonflyBaseNetworkAdapter — transport ──────────────────────────────

  @override
  Future<List<Map<String, Object?>>> requestList(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final result = await _dispatch(method, path, query: query, body: body);
    if (result is List) return result.cast<Map<String, Object?>>();
    throw FormatException('Expected List, got ${result.runtimeType}');
  }

  @override
  Future<Map<String, Object?>> requestObject(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final result = await _dispatch(method, path, query: query, body: body);
    if (result is Map) return Map<String, Object?>.from(result);
    throw FormatException('Expected Map, got ${result.runtimeType}');
  }

  /// Routes an HTTP-method + path to the matching gRPC unary call,
  /// then serializes the protobuf response to a JSON-compatible map.
  Future<Object?> _dispatch(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    await beforeRequest();

    final stopwatch = Stopwatch()..start();

    try {
      Object? result;

      // GET /users/{id}
      if (method == HttpMethods.get && path.startsWith('/users/')) {
        final id = int.parse(path.split('/').last);
        final response = await _userClient.getUser(GetUserRequest(id: id));
        result = _protoToMap(response);

      // POST /users
      } else if (method == HttpMethods.post && path == '/users') {
        final request = CreateUserRequest()
          ..name = (body as Map)['name'] as String
          ..email = (body as Map)['email'] as String;
        final response = await _userClient.createUser(request);
        result = _protoToMap(response);

      // GET /users
      } else if (method == HttpMethods.get && path == '/users') {
        final request = ListUsersRequest()
          ..pageSize = int.tryParse(query?['pageSize']?.toString() ?? '20')
          ..pageToken = query?['pageToken'] as String?;
        final response = await _userClient.listUsers(request);
        result = response.users.map(_protoToMap).toList();

      } else {
        throw UnimplementedError('No gRPC mapping for $method $path');
      }

      if (enableLogging) {
        _log.info(
          'gRPC $method $path completed in ${stopwatch.elapsedMilliseconds}ms',
          source: 'DragonflyGrpcAdapter',
        );
      }

      await afterResponse(result);
      return result;

    } catch (e, stackTrace) {
      stopwatch.stop();
      _log.error(
        'gRPC $method $path failed',
        error: e,
        stackTrace: stackTrace,
        source: 'DragonflyGrpcAdapter',
      );
      rethrow;
    }
  }

  /// Converts a protobuf message to a JSON-compatible map, matching what
  /// the repository generator expects from `requestObject`/`requestList`.
  static Map<String, Object?> _protoToMap(GeneratedMessage message) {
    // protobuf 3.x+ supports `toProto3Json()` which produces clean maps.
    // For older versions, use `jsonEncode(message.writeToJsonMap())`.
    return jsonDecode(
      const JsonEncoder().convert(message.toProto3Json()),
    ) as Map<String, Object?>;
  }

  // ── Legacy methods (delegate to new API) ─────────────────────────────────

  @override
  Future<List<Map<String, Object?>>> callForList(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) {
    final isQuery = method == HttpMethods.get || method == HttpMethods.delete;
    return requestList(
      method,
      path,
      query: isQuery ? params : null,
      body: isQuery ? null : params,
      headers: options?.headers,
    );
  }

  @override
  Future<Map<String, Object?>> callForObject(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) {
    final isQuery = method == HttpMethods.get || method == HttpMethods.delete;
    return requestObject(
      method,
      path,
      query: isQuery ? params : null,
      body: isQuery ? null : params,
      headers: options?.headers,
    );
  }

  // ── Streaming (DragonflyRealtimeAdapter) ──────────────────────────────────

  @override
  Stream<Map<String, Object?>> subscribeToObject(
    String channel, {
    Map<String, dynamic>? params,
  }) {
    // Map channel names to server-streaming gRPC methods.
    // Example: channel 'user.created' → EventService.Subscribe()
    final request = SubscribeRequest()..channel = channel;
    return _eventClient.subscribe(request).map((event) {
      return _protoToMap(event);
    });
  }

  @override
  Stream<List<Map<String, Object?>>> subscribeToList(
    String channel, {
    Map<String, dynamic>? params,
  }) {
    return subscribeToObject(channel, params: params).map((obj) => [obj]);
  }

  @override
  Future<void> publish(String channel, Map<String, dynamic> payload) async {
    final request = PublishRequest()
      ..channel = channel
      ..payload = jsonEncode(payload);
    await _eventClient.publish(request);
  }
}
```

---

## 3. The config — `dragonfly_grpc_config.dart`

This is what the app developer adds to `DragonflyConfig.adapters`. It
registers the adapter in the DI container under a connection name so
generated repositories can find it.

```dart
import 'package:dragonfly/dragonfly.dart';

import 'dragonfly_grpc_adapter.dart';

/// Registers [DragonflyGrpcAdapter] in the DI container.
///
/// ```dart
/// @override
/// List<DragonflyAdapterConfig> get adapters => [
///   DragonflyHttpAdapterConfig(options: ...),
///   DragonflyGrpcConfig(baseUrl: 'localhost:50051', connectionName: 'grpc'),
/// ];
/// ```
class DragonflyGrpcConfig extends DragonflyAdapterConfig {
  const DragonflyGrpcConfig({
    required this.baseUrl,
    this.connectionName = 'grpc',
    this.enableLogging = true,
  });

  /// The gRPC server address (host:port).
  final String baseUrl;

  /// Connection name — must match `@Repository(connection: )`.
  final String connectionName;

  final bool enableLogging;

  @override
  void initConfig(DragonflyContainer container) {
    if (container.isRegistered<DragonflyBaseNetworkAdapter>(
        instanceName: connectionName)) {
      return;
    }

    final adapter = DragonflyGrpcAdapter(
      baseUrl: baseUrl,
      enableLogging: enableLogging,
    );

    // Register under the interface type (what generated repos resolve).
    container.registerSingleton<DragonflyBaseNetworkAdapter>(
      adapter,
      instanceName: connectionName,
    );

    // Also register under the concrete type for hand-written code.
    container.registerSingleton<DragonflyGrpcAdapter>(
      adapter,
      instanceName: connectionName,
    );

    // Authenticated variant — if this adapter wraps a DragonflyGrpcAdapter,
    // @Authenticated() methods resolve here.
    container.registerSingleton<DragonflyBaseNetworkAdapter>(
      DragonflyAuthenticatedAdapter(inner: adapter),
      instanceName: '$connectionName:authenticated',
    );

    // Register streaming interface for @Subscribe methods.
    container.registerSingleton<DragonflyRealtimeAdapter>(
      adapter,
      instanceName: connectionName,
    );
  }
}
```

---

## 4. The repository — `user_grpc_repository.dart`

Standard `@Repository` annotation. The `connection` field matches the
`DragonflyGrpcConfig.connectionName`. The generator emits normal method
bodies — it doesn't know or care that the adapter is gRPC.

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'user_grpc_repository.repository.dart';

/// gRPC-backed user repository.
///
/// `connection: 'grpc'` routes every method through [DragonflyGrpcAdapter]
/// instead of the default HTTP adapter.
@Repository(url: '', connection: 'grpc')
abstract class UserGrpcRepository {
  factory UserGrpcRepository() = _UserGrpcRepository;

  /// GET /users → userClient.listUsers()
  @Get(path: '/users')
  Future<ServiceResponse<User>> listUsers({
    @Query('pageSize') int? pageSize,
    @Query('pageToken') String? pageToken,
  });

  /// GET /users/{id} → userClient.getUser(id: ...)
  @Get(path: '/users/{id}')
  Future<User> getUserById(@Path('id') int id);

  /// POST /users → userClient.createUser(...)
  /// @Authenticated() resolves the ':authenticated' variant.
  @Post(path: '/users')
  @Authenticated()
  Future<User> createUser(@Body() User user);
}
```

---

## 5. The app config — `app_config.dart`

The developer adds both their HTTP and gRPC adapters to the unified
`adapters` list:

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_grpc/dragonfly_grpc.dart';

import 'injector.dart';

@RouterConfig()
class AppConfig extends DragonflyConfig with $AppConfig {

  @override
  List<DragonflyAdapterConfig> get adapters => [
    // Built-in — REST API for character data
    DragonflyHttpAdapterConfig(
      connectionName: 'defaultHttpNetwork',
      options: const DragonflyHttpBaseOptions(
        baseUrl: 'https://rickandmortyapi.com/api/',
      ),
    ),
    // Community — gRPC for user data
    DragonflyGrpcConfig(
      baseUrl: 'localhost:50051',
      connectionName: 'grpc',
    ),
  ];

  @override
  DragonflyInjector? get injector => DragonflyInjector(
    inject: (container) async {
      await initDragonflyContainer();
    },
  );
}
```

---

## 6. Generated repository output

The generator emits code that resolves the adapter by connection name.
It doesn't care whether the adapter is HTTP, gRPC, or WebRTC — the
contract is `DragonflyBaseNetworkAdapter`:

```dart
// GENERATED CODE — user_grpc_repository.repository.dart

class _$UserGrpcRepository extends UserGrpcRepository {

  @override
  Future<ServiceResponse<User>> listUsers({int? pageSize, String? pageToken}) async {
    final log = DragonflyLogManager.instance;
    final stopwatch = Stopwatch()..start();

    try {
      // Resolves DragonflyGrpcAdapter (registered under 'grpc')
      final DragonflyBaseNetworkAdapter network = DragonflyContainer.I
          .get<DragonflyBaseNetworkAdapter>(instanceName: 'grpc');

      final Map<String, Object?> response = await network.requestObject(
        HttpMethods.get,
        '/users',
        query: {'pageSize': pageSize, 'pageToken': pageToken},
      );

      return ServiceResponse.fromJson(
        response as Map<String, Object?>,
        (json) => User.fromJson(json as Map<String, Object?>),
      );
    } catch (e, stackTrace) {
      log.error('UserGrpcRepository.listUsers failed',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<User> getUserById(int id) async {
    // GET /users/{id} → adapter._dispatch() routes to userClient.getUser()
    final DragonflyBaseNetworkAdapter network = DragonflyContainer.I
        .get<DragonflyBaseNetworkAdapter>(instanceName: 'grpc');

    final Map<String, Object?> response = await network.requestObject(
      HttpMethods.get,
      '/users/$id',
    );

    return User.fromJson(response as Map<String, Object?>);
  }

  @override
  @Authenticated()
  Future<User> createUser(User user) async {
    // Authenticated — resolves the :authenticated variant
    final DragonflyBaseNetworkAdapter network = DragonflyContainer.I
        .get<DragonflyBaseNetworkAdapter>(instanceName: 'grpc:authenticated');

    final Map<String, Object?> response = await network.requestObject(
      HttpMethods.post,
      '/users',
      body: user.toJson(),
    );

    return User.fromJson(response as Map<String, Object?>);
  }
}
```

---

## How the pieces connect

```
AppConfig.adapters
  │
  ├── DragonflyHttpAdapterConfig
  │     └── registers DragonflyNetworkHttpAdapter as 'defaultHttpNetwork'
  │
  └── DragonflyGrpcConfig
        ├── registers DragonflyGrpcAdapter as 'grpc'
        └── registers DragonflyAuthenticatedAdapter(DragonflyGrpcAdapter) as 'grpc:authenticated'

UserGrpcRepository (@Repository(connection: 'grpc'))
  │
  ├── listUsers()    → DragonflyContainer.I.get<DragonflyBaseNetworkAdapter>('grpc')
  │                     → DragonflyGrpcAdapter.requestObject(GET, '/users')
  │                     → userClient.listUsers()
  │
  ├── getUserById()  → DragonflyGrpcAdapter.requestObject(GET, '/users/{id}')
  │                     → userClient.getUser(id: ...)
  │
  └── createUser()   → DragonflyContainer.I.get<DragonflyBaseNetworkAdapter>('grpc:authenticated')
                        → DragonflyAuthenticatedAdapter.requestObject(POST, '/users')
                        → beforeRequest() — refresh token
                        → buildHeaders()  — inject Authorization
                        → DragonflyGrpcAdapter._dispatch(POST, '/users') → userClient.createUser()
```

The key insight: **the repository generator emits the same code regardless of
transport**. It calls `requestObject`/`requestList` on whatever adapter is
registered under the connection name. The adapter is responsible for
translating the HTTP-method + path convention into its own protocol.

[← Back to README.md](../../README.md)
