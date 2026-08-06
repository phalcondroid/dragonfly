# Runtime architecture (`package:dragonfly`)

Internals of the runtime library. The runtime contains **no code generation** — it is the
set of types that generated code refers to by name.

Everything lives under `dragonfly/lib/framework/` and is re-exported through
`dragonfly/lib/dragonfly.dart`. That barrel uses explicit `show` clauses on every export,
so **a new public type is invisible until you add it there**.

---

## Layering

Dragonfly prescribes a component-per-feature layout. `example/` follows it:

```
lib/components/<component>/
├── config/           injector.dart  (@InjectableInit)  + generated .config.dart
├── data/
│   ├── models/       @FactoryModel  → .model.dart
│   └── repositories/ @Repository    → .repository.dart
├── domain/
│   ├── use_cases/    @UseCase, returns Either<Error, T>
│   └── forms/        @FormSchema    → .form.dart
└── presentation/
    ├── states/       @StateModel    → .state.dart (StateModel mode only)
    ├── features/     @StateManager  → .state_manager.dart
    └── screens/      @Screen(stateManager: X) → .view.dart
```

Data flows one direction: **screen → state manager → use case → repository → network**.
Results come back as `Either<Error, T>` and are folded into a sealed state.

---

## Dependency injection — `DragonflyContainer`

`framework/di/dragonfly_container.dart`. A hand-written `get_it` replacement.

- Singleton accessed as `DragonflyContainer.I` (or `.instance`).
- Storage is `List<Map<_ServiceKey, _ServiceEntry>>` — a **stack of scopes**. Lookup walks
  `_scopes.reversed`, so the innermost scope shadows outer ones.
- `_ServiceKey` is `(Type, String? name)`. Named instances are first-class.
- `_ServiceEntry` has seven named constructors: `singleton`, `lazy`, `factory`,
  `factoryParam`, `asyncSingleton`, `asyncLazySingleton`, `asyncFactory`,
  `asyncFactoryParam`. `asyncSingleton` starts resolving immediately in its constructor.

Registration API mirrors `get_it`: `registerSingleton`, `registerLazySingleton`,
`registerFactory`, `registerFactoryParam`, `registerSingletonAsync`,
`registerLazySingletonAsync`, `registerFactoryAsync`, `registerFactoryParamAsync`,
`registerSingletonWithDependencies`.

Retrieval: `get<T>({instanceName, param1, param2, type})`, `getAsync<T>(...)`, and
`call<T>(...)`. Throws a plain `Exception` when the key is absent.

Scopes: `pushNewScope({init, scopeName, dispose, isFinal})` / `popScope()` — `popScope`
awaits each entry's `dispose`.

Debugging: `debugPrintRegisteredInstances()` prints a box-drawn table of every scope and
entry kind. Use it first when DI misbehaves.

`_register` **throws** `DragonflyException` on duplicate registrations (set
`allowReassignment = true` to override). `allReady()` / `allReadySync()` /
`isReady()` are implemented — they await / check completion of non-lazy async
singletons across all scopes. `DragonflyContainer.reset()` clears all scopes
for test teardown.

### How wiring gets generated

`InjectableConfigGenerator` globs the whole package, runs `InjectableVisitor` over every
class, sorts by `orderPosition`, and emits:

```dart
extension DragonflyContainerConfigX on DragonflyContainer {
  Future<void> configureDependencies() async {
    final gh = DragonflyContainer.I;
    gh.registerLazySingleton<CharacterRepository>(() => CharacterRepository());
    gh.registerFactory<GetUserListUseCase>(
        () => GetUserListUseCase(gh.get<CharacterRepository>()),
        instanceName: 'GetUserList');
  }
}
```

Registration kind is fixed per annotation, not configurable:

| Annotation | Kind |
| ---------- | ---- |
| `@Repository` | lazy singleton |
| `@UseCase` | factory |
| `@Injectable` | factory |
| `@Singleton` | eager singleton |
| `@LazySingleton` | lazy singleton |
| `@StateManager` delegate | factory |
| `$XController` (generated) | lazy singleton, with `dispose` wired |

`InjectableVisitor` skips anything whose `allSupertypes` include `StatelessWidget`,
`StatefulWidget`, or `Widget`, so screens are never registered.

---

## Network layer

`framework/network/`.

```dart
abstract interface class DragonflyBaseNetworkAdapter {
  Future<List<Map<String, Object?>>> callForList(
      HttpMethods method, String path, Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);
  Future<Map<String, Object?>> callForObject(
      HttpMethods method, String path, Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);
}
```

Two lines wide on purpose: generated repositories only ever call these two methods.

`DragonflyNetworkHttpAdapter` implements it over `package:http`:

- `_buildUri` joins `config.baseUrl` and `path` (normalising slashes) and appends
  `params` as a query string **for GET and DELETE only**.
- `_encodeBody` JSON-encodes `params` for POST/PUT/PATCH/DELETE.
- Emits a correlated request/response log pair via `DragonflyLogManager` using a
  generated request id.
- `_validateResponse` throws `DragonflyHttpException(message, statusCode, body)` on
  status ≥ 400.

`DragonflyAuthenticatedAdapter` (`framework/session/`) wraps **any**
`DragonflyBaseNetworkAdapter` and adds the
session token, 401 handling via `onTokenExpired`, and an optional `refreshTokenCallback`.
The deprecated `AuthenticatedNetworkAdapter` (HTTP-only) is kept for backward compat.

### Realtime transport

`DragonflyRealtimeAdapter` is the streaming counterpart of
`DragonflyBaseNetworkAdapter`:

```dart
abstract interface class DragonflyRealtimeAdapter {
  DragonflyRealtimeState get state;
  Stream<DragonflyRealtimeState> get stateStream;
  Future<void> connect();
  Future<void> disconnect();
  Stream<Map<String, Object?>> subscribeToObject(String channel, {Map<String, dynamic>? params});
  Stream<List<Map<String, Object?>>> subscribeToList(String channel, {Map<String, dynamic>? params});
  Future<void> publish(String channel, Map<String, dynamic> payload);
}
```

`DragonflyWebSocketAdapter` implements it. It depends on the narrow
`DragonflySocketConnection` (`messages` / `send` / `close`) rather than on
`WebSocketChannel`, which is what makes it testable and leaves room for other
transports. `WebSocketConnection` is the production binding.

Registered by connection name through `DragonflyWebSocketAdapterConfig`, under **both**
`DragonflyRealtimeAdapter` and `DragonflyWebSocketAdapter` — generated code asks for the
interface. Connects lazily on first `listen`.

See `docs/ai/known-gaps.md` #10 for envelope shape, reconnect behaviour, and the
subscribe-deduplication rule.

### Adapter registration by connection name

**New pattern (preferred):** Subclass `DragonflyAdapterConfig` and add instances to
`DragonflyConfig.adapters`. Built-in subclasses:

- `DragonflyHttpAdapterConfig` — registers `DragonflyNetworkHttpAdapter` under
  `connectionName` and `DragonflyAuthenticatedAdapter` under
  `'$connectionName:authenticated'`.
- `DragonflyWebSocketAdapterConfig` — registers `DragonflyWebSocketAdapter` under
  `connectionName`.

```dart
class AppConfig extends DragonflyConfig {
  @override
  List<DragonflyAdapterConfig> get adapters => [
    DragonflyHttpAdapterConfig(options: DragonflyHttpBaseOptions(baseUrl: 'https://...')),
    DragonflyWebSocketAdapterConfig(config: DragonflyRealtimeConfig(url: 'wss://...')),
  ];
}
```

`DragonflyApp.init()` iterates `config.adapters` and calls `initConfig(container)` on each.

**Deprecated pattern** (still works): `instanceConfigs` (`DragonflyInstanceConfig`) and
`realtimeConfigs` (`DragonflyRealtimeInstanceConfig`) are kept for backward compat.
Internally they mirror the same logic as their replacement classes.

### Resolution at runtime

Generated repositories resolve adapters from the DI container:

- HTTP methods → `DragonflyContainer.I.get<DragonflyBaseNetworkAdapter>(instanceName: connectionName)`
- `@Authenticated` methods → `instanceName: '$connectionName:authenticated'`
- `@Subscribe` methods → `DragonflyContainer.I.get<DragonflyRealtimeAdapter>(instanceName: realtimeConnection)`

Both HTTP and realtime adapters are registered under the **interface** type
(`DragonflyBaseNetworkAdapter` / `DragonflyRealtimeAdapter`) and the concrete type
(`DragonflyNetworkHttpAdapter` / `DragonflyWebSocketAdapter`). Generated code resolves
the interface.

---

## State management runtime (v2)

`framework/state/`. The old `framework/feature/` and `framework/bloc/` directories were
deleted in the v2 clean break.

### `DragonflyController<S>` — `state_controller.dart`

The runtime base for generated controllers. App code never subclasses it by hand — the
state manager generator emits one concrete `$XController` per `@StateManager` class.

- Holds `S _state` plus one broadcast `StreamController`; `state` is readable
  synchronously, `stream` drives widgets.
- `emit(S)` is `@protected` — only the controller (generated code) mutates state.
  Logging (`viewStateChange`) fires when the generated override of `loggingEnabled`
  returns true (`@StateManager(logging: true)`).
- Rate limiting: `schedule(key, body, {debounce, throttle})`, `cancelScheduled`,
  `flushScheduled`, `isScheduledPending`, backed by `ActionScheduler`. This is what makes
  `@Event(debounce:/throttle:)` work; pending calls are cancelled in `dispose()`.
- `dispose()` is idempotent and closes the stream. The generated DI registration wires it
  via `registerLazySingleton(..., dispose: (c) => c.dispose())`.

### `DragonflyStateBuilder<S>` — `state_builder.dart`

The one widget every generated builder returns. Reads the current state synchronously on
creation (first frame is real state, not a blank), then rebuilds from the stream, gated
by an optional `buildWhen(previous, current)`.

### What the generator emits

For `@StateManager class UserStateManager` (easy mode, no `state:` argument):

- `sealed class UserStateManagerState` — variants: built-in `initial`, `loading`,
  `error({required String message})`, plus one per `@Event` method, named after it, with
  the method's return type as a `value` payload (`Future<void>` events get a zero-payload
  variant; `Future<Either<L, R>>` is folded — `Right` is the payload, `Left` becomes
  `error`). Includes `when`/`maybeWhen` over a Dart 3 exhaustive `switch`.
- `class $UserStateManagerController extends DragonflyController<...>` — holds the
  delegate; each `@Event` becomes a dispatcher emitting `loading` → invoking → emitting
  the variant, catching exceptions into `error`. Plain public methods are forwarded
  untouched. Debounced/throttled events route through `schedule`.

For `@StateManager(state: CharacterState)` (StateModel mode): no state class is
generated. `@Event` methods must return `CharacterState` (or `Future<CharacterState>`)
and the returned value is emitted as-is. `loading` is auto-emitted only if the model
declares a zero-arg `loading` factory; exceptions are emitted only if it declares
`error({required String message})`. The model must declare a zero-arg `initial` factory
(starting state) or generation fails with an explicit error.

For `@StateView(UserStateManager) class UserScreen ... with $UserStateManager`:

- `mixin $UserStateManager` (in `.view.dart`) flattening the API onto the widget:
  event dispatchers (`initialize(session)`), plain-method forwarders, `when({...,
  required orElse})` (rebuilds on change; all callbacks optional), one typed
  `build<Event>(builder, {orElse})` per variant, and `buildFor('event', builder)` — the
  string-keyed escape hatch with a `dynamic` payload (renamed from the sketch's `build`
  because `StatelessWidget.build(BuildContext)` already exists).

### DI shape

`InjectableVisitor` registers two entries per `@StateManager`: the delegate as a
factory, and the generated controller as a **lazy singleton** with `dispose`. Singleton
controllers are what make the flattened view API possible — the mixin resolves
`DragonflyContainer.I.get<$XController>()` with no `BuildContext`, so no provider
wrapping exists anywhere (the router no longer emits one; `@Screen(provider:)` was
removed). One controller per container scope; push/pop a container scope to reset state.

---

## Session and ACL

`framework/session/dragonfly_session_manager.dart`. Singleton `DragonflySessionManager.instance`,
also exported as the top-level `dragonflySession`.

- `SessionState`: `loading`, `authenticated`, `unauthenticated`, `expired`.
- `init({config, storage, onAccessDenied})` restores a persisted session if
  `persistSession` is set.
- `login<T>({token, user, roles, permissions, expiresIn})` / `logout()` /
  `refreshToken(newToken, {expiresIn})`.
- Reads: `isAuthenticated`, `isExpired`, `token`, `authorizationHeader`,
  `getUser<T>(fromJson)`, `getUserField<T>(field)`.
- RBAC: `hasRole`, `hasAnyRole`, `hasAllRoles`; permissions: `hasPermission`,
  `hasAnyPermission`, `hasAllPermissions`; mutators `addRoles` / `removeRoles` /
  `addPermissions` / `removePermissions`.
- Observation: `stateStream`, `addStateListener` / `removeStateListener`.
- `checkAccess({accessLevel, requiredRoles, requiredPermissions, customRedirectOnDenied,
  customRedirectOnUnauthenticated})` returns a redirect path or `null`. **This is the
  method generated routers call.**

Storage is pluggable via `SessionStorage`: `InMemorySessionStorage` and
`HiveSessionStorage`. The Hive one takes a `dynamic _box` and duck-types it — the package
does not actually import Hive.

---

## Routing

Two implementations; see `known-gaps.md` #5 for which one is live.

- `DragonflyRouter` (`framework/navigation/router.dart`) — runtime singleton, plain
  `Map<String, WidgetBuilder>`, fade transitions, **no ACL**.
- The generated `$AppRouterConfig` mixin — `routes`, `routeConfigs`, `namedRoutes`,
  `initialRoute`, and an `onGenerateRoute` that calls `session.checkAccess(...)` before
  building, redirecting on denial. This is what `example/`'s `MaterialApp` uses.

`navigation_extensions.dart` adds `BuildContext` navigation helpers.

---

## Logging

`framework/logging/`. `DragonflyLogManager.instance`, aliased as `dragonflyLog`.

Levels: `debug`, `info`, `success`, `warning`, `error`, `danger`, `request`, `response`.
Control with `setEnabled`, `setMinLevel`, `enableHistory(maxSize:)`.

Structured entry points used by generated code — keep these stable, generators emit calls
to them by name:

- `repositoryStart` / `repositorySuccess` / `repositoryError`
- `request` / `response` / `generateRequestId`
- `viewInit`, `viewStateChange`, `viewActionStart`, `viewActionEnd`, `viewStep`,
  `viewSideEffect`, `viewSubscribe`, `viewSubscriptionError`, `viewSubscriptionDone`,
  `viewCancelSubscription`, `viewUseCase`, `viewDispose`

Output uses Unicode box-drawing and emoji, deliberately **without ANSI colour**.
Observers: `addListener(cb)` and `logStream`.

---

## Functional and mapping utilities

`Either<L, R>` (`framework/functional/either.dart`) — hand-written, sealed into `Left` and
`Right`:

`fold(onLeft, onRight)`, `isLeft` / `isRight`, `getLeft()` / `getRight()` (throw on the
wrong side), `getOrElse(R defaultValue)`, `getOrElseCompute(R Function(L))`, `swap()`,
and statics `Either.tryCatch(run, onError)`, `Either.tryCatchAsync(run, onError)`,
`Either.fromNullable(value, onNull)`, `Either.map2(a, b, combine)`.

Note `getOrElse` takes a **value**, `getOrElseCompute` takes a **function**. `README.md`
shows `getOrElse(() => defaultUser)`, which is wrong.

`JsonDatatypeMapper` (`framework/mapper/`) — the safe-casting helper generated models
call: `mapFor<T>(json, key, {defaultValue})`, `mapNestedObject<T>`, `mapGenericList<T>`,
`mapForTypeParameter<T>`. Throws `JsonMappingException`.

`framework/datamapper/` holds `Hydrator` / `Dryer` and `framework/converters/json_converter.dart`
a `JsonConverter` contract.

---

## Forms

`framework/form/`. Runtime half of `@FormSchema`.

- `FormFieldState<T>` — value, initialValue, error, touched, dirty. **Name collides with
  Flutter's `FormFieldState`**; see `known-gaps.md` #3.3.
- `Validators` — the static library the generated code calls into; `Validator` and
  `CrossFieldValidator` are the function typedefs.
- `FormController` / `FormControllerMixin` — what generated form state extends. The mixin
  is constrained `on DragonflyController<S>` since v2 (it targeted the deleted
  `StateManager<S>` before).
- `validated_widgets.dart` — `ValidatedTextField`, `ValidatedDropdown`, `ValidatedCheckbox`,
  `ValidatedSwitch`, `ValidatedDatePicker`, `ValidatedForm`, `ValidatedSubmitButton`. Each
  takes a required `stateController: DragonflyController<S>` and rebuilds through
  `DragonflyStateBuilder` (the old provider-resolved `StateManagerBuilder` is gone).

The generated half does not currently compile. Treat this subsystem as unfinished.

---

## Bootstrap

```dart
await DragonflyApp(config: AppConfig()).init();
```

`DragonflyApp.init()` in order: configures the log manager → prints the banner →
`initConfig(container)` on every entry in `config.adapters` (registering network adapters,
both built-in and custom) → also processes deprecated `instanceConfigs` and
`realtimeConfigs` for backward compat →
`await config.injector?.inject!(DragonflyContainer.I)`.

That last callback is where the app calls its generated `initDragonflyContainer()` and
configures the router. Note the `!` — a `DragonflyInjector` with a null `inject` throws.
