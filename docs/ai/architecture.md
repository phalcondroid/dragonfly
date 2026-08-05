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
├── config/           injector.dart  (@DragonflyInjectableInit)  + generated .config.dart
├── data/
│   ├── models/       @FactoryModel  → .model.dart
│   └── repositories/ @Repository    → .repository.dart
├── domain/
│   ├── use_cases/    @InjectableUseCase, returns Either<Error, T>
│   └── forms/        @FormSchema    → .form.dart
└── presentation/
    ├── states/       @StateModel    → .state.dart
    ├── features/     @DragonflyStateManager → .state_manager.dart
    └── screens/      @DragonflyScreen, plain widgets
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

**Two behaviours to know** (both in `known-gaps.md`):
`_register` silently returns on a duplicate key instead of throwing, and `allReady()` /
`allReadySync()` / `isReady()` are no-op stubs.

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
| `@InjectableUseCase` | factory |
| `@DragonflyStateManager` | factory |
| `@DragonflyBloc` | factory |

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

`AuthenticatedNetworkAdapter` (`framework/session/`) wraps the same interface and adds the
session token, 401 handling via `onTokenExpired`, and an optional `refreshTokenCallback`.

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

Registered by connection name through `DragonflyRealtimeInstanceConfig`, under **both**
`DragonflyRealtimeAdapter` and `DragonflyWebSocketAdapter` — generated code asks for the
interface. Connects lazily on first `listen`.

See `docs/ai/known-gaps.md` #10 for envelope shape, reconnect behaviour, and the
subscribe-deduplication rule.

### Adapter registration by connection name

`DragonflyInstanceConfig.initConfig()` registers a `DragonflyNetworkHttpAdapter` **under a
string name**, defaulting to the `defaultHttpNetwork` constant:

```dart
DragonflyContainer.I.registerSingleton(
    DragonflyNetworkHttpAdapter(config: config), instanceName: connectionName);
```

`@Repository(connection: 'x')` makes the generated code do
`DragonflyContainer.I.get<DragonflyNetworkHttpAdapter>(instanceName: 'x')`. Multiple named
backends are configured by adding more `DragonflyInstanceConfig` entries to
`DragonflyConfig.instanceConfigs`.

Note the generated HTTP lookup asks for the **concrete** `DragonflyNetworkHttpAdapter`, not
the `DragonflyBaseNetworkAdapter` interface — so a custom adapter registered only under the
interface type will not be found by generated repositories. Worth fixing; the realtime path
deliberately does the opposite, resolving `DragonflyRealtimeAdapter` (the interface) and
registering the implementation under both.

Realtime transports are registered the same way, from `DragonflyConfig.realtimeConfigs`,
and selected with `@Repository(realtimeConnection: 'x')`.

---

## State management runtime

`framework/feature/` (directory name is historical; the classes are `StateManager*`).

### `StateManager<S>`

- Holds `S _state` plus two broadcast controllers: `stream` (states) and `sideEffects`.
- `emit(S)` is `@protected` — only the manager mutates its own state.
- `sideEffect(StateManagerSideEffect)` pushes onto the side-effect stream. Built-in
  effects: `NavigateTo`, `ShowSnackbar`, `ShowDialog`, `Pop`.
- Subscription management: `subscribe(key, stream, onData:…)`, `cancelSubscription(key)`,
  `cancelAllSubscriptions()`, `pauseSubscription`, `resumeSubscription`, plus
  `hasSubscription` / `activeSubscriptions`. Keyed by string; re-subscribing with the same
  key cancels the previous one first. This is the hook for consuming a repository's
  realtime `Stream`.
- Action rate limiting: `scheduleAction(key, body, {debounce, throttle})`,
  `cancelScheduledAction`, `flushScheduledAction`, `isActionPending`. Backed by
  `ActionScheduler`; every pending call is cancelled in `dispose()`.
- DI access: `useCase<T>()` and `get<T>({instanceName})` delegate to the container.
- Lifecycle: `onInit()` and `onDispose()` overrides; `dispose()` is `@mustCallSuper` and
  cancels all subscriptions before closing both controllers.
- Logging: `loggingEnabled` is a getter overridden by the generated mixin. Manual helpers
  `logActionStart` / `logActionEnd` / `logStep` must be called by hand — the generator does
  not inject them.

### Widgets

| Widget | Purpose |
| ------ | ------- |
| `StateManagerProvider<SM>` | `InheritedWidget` + `StatefulWidget`; owns the instance and disposes it. `lazy` defaults to `true`. `updateShouldNotify` returns **`false`** — rebuilds come from the stream, not from inherited-widget propagation |
| `StateManagerBuilder<SM, S>` | Rebuilds on each state, gated by `buildWhen` |
| `StateManagerListener<SM, S>` | Side-effect-free callback on state change, gated by `listenWhen` |
| `StateManagerSideEffectListener<SM>` | Subscribes to the side-effect stream |
| `StateManagerConsumer<SM, S>` | Builder + listener |
| `StateManagerSelector<SM, S, T>` | Rebuilds only when the selected slice changes |
| `StateScope<SM>` | **Preferred entry point.** Resolves from DI, provides, handles side effects, and disposes — replaces the Provider + `DefaultSideEffectHandler` stack |
| `StateView<SM, S>` | **Preferred screen base.** `buildState(context, state, manager)` plus an overridable `buildWhen` |
| `StateSelector<SM, S, T>` | Rebuilds only when the selected slice changes |
| `DragonflyScreenBase<SM, S>` | Older base class exposing `buildScreen(context, sm, state)` |
| `ScreenProvider<SM>` | Wraps a screen, resolving `SM` from DI |
| `DefaultSideEffectHandler<SM>` | Maps the four built-in effects to `Navigator` / `ScaffoldMessenger` / `showDialog`, with per-effect overrides |

Access from a widget: `context.stateManager<SM>()`.

### What the generator adds on top

For `@DragonflyStateManager class CharacterFeature extends StateManager<CharacterState>`:

- `mixin _$CharacterFeatureMixin on StateManager<CharacterState>` — only overrides
  `loggingEnabled`.
- `class CharacterFeatureProvider extends StatelessWidget` — resolves from DI by default.
- One builder widget **per sealed state variant**: `CharacterInitial`, `CharacterLoading`,
  `CharacterLoaded`, `CharacterCharacterList`, `CharacterError`. Each takes a typed
  `builder` receiving the variant's fields, plus `buildWhen`, `orElse`, and an
  `initial<Field>` seed.
- `extension CharacterFeatureBuildContextExtension on BuildContext` with a
  `characterFeature` getter and an exhaustive `characterFeatureBuilder({onInitial, …})`.

The per-variant builder widgets are the framework's main boilerplate win. They come from
the **state type's variants**, discovered by `_findStateVariants`, not from `@StateAction`.

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
- `FormController` / `FormControllerMixin` — what generated form state extends.
- `validated_widgets.dart` — `ValidatedTextField`, `ValidatedDropdown`, `ValidatedCheckbox`,
  `ValidatedSwitch`, `ValidatedDatePicker`, `ValidatedForm`, `ValidatedSubmitButton`.

The generated half does not currently compile. Treat this subsystem as unfinished.

---

## Bootstrap

```dart
await DragonflyApp(config: AppConfig()).init();
```

`DragonflyApp.init()` in order: configures the log manager → prints the banner →
`initConfig()` on every `DragonflyInstanceConfig` (registering network adapters) →
`await config.injector?.inject!(DragonflyContainer.I)`.

That last callback is where the app calls its generated `initDragonflyContainer()` and
configures the router. Note the `!` — a `DragonflyInjector` with a null `inject` throws.
