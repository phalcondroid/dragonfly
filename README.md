# Dragonfly Framework

An opinionated Flutter framework that replaces your entire pubspec stack — freezed,
injectable, get_it, retrofit, bloc, fpdart, json_serializable — with **one annotation
set and one code-generator suite**. App authors write only models, use cases, state
managers and screens. Everything else is generated.

---

## Table of Contents

- [Packages](#packages)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Project layout](#project-layout)
- [Models](#models)
- [Repositories](#repositories)
- [Use cases](#use-cases)
- [States](#states)
- [State managers](#state-managers)
- [Screens](#screens)
- [Routing](#routing)
- [Dependency injection](#dependency-injection)
- [Configuration](#configuration)
- [Component barrel](#component-barrel)
- [Forms](#forms)
- [Sessions & ACL](#sessions--acl)
- [Logging](#logging)
- [Runtime primitives](#runtime-primitives)
- [Annotations reference](#annotations-reference)
- [Generated files](#generated-files)
- [Build & verify](#build--verify)
- [Debugging](#debugging)
- [Troubleshooting](#troubleshooting)

---

## Packages

| Package | Role | Dependencies |
|---------|------|-------------|
| `dragonfly` | Runtime: DI container, network, state management, session, logging, forms | Flutter SDK |
| `dragonfly_annotations` | Annotation classes only — no logic, no Flutter | `meta` |
| `dragonfly_builder` | `source_gen` builders that read those annotations | `analyzer`, `source_gen`, `build` |

Strict dependency direction:
```
dragonfly_builder ──▶ dragonfly_annotations ◀── dragonfly
                                                    ▲
example ────────────────────────────────────────────┘
```

`dragonfly_builder` must **never** import `package:dragonfly`. It emits references to
runtime types as string literals.

---

## Architecture

Data flows one direction through four layers:

```
Screen (Widget)                @Screen, @StateView + $Manager mixin
    │  dispatch events, rebuild from state
    ▼
State Manager (plain class)    @StateManager, @Event methods returning values
    │  business logic, orchestrates use cases
    ▼
Use Case (plain class)         @UseCase, hand-written call method
    │  data transformation, returns Either<Error, T>
    ▼
Repository (abstract)          @Repository, generated HTTP / realtime client
    │  network calls, model deserialization
    ▼
Network Adapter (runtime)      DragonflyBaseNetworkAdapter, HTTP & WebSocket
```

Every layer is generated except the state manager delegate and the use case body.
Models, repository implementations, state sealed classes, controllers, view mixins,
DI configuration and router configuration are all build outputs.

---

## Getting started

### 1. Dependencies

```yaml
# pubspec.yaml
dependencies:
  dragonfly:
    path: ../dragonfly
  dragonfly_annotations:
    path: ../dragonfly_annotations

dev_dependencies:
  build_runner: ^2.15.0
  dragonfly_builder:
    path: ../dragonfly_builder
```

### 2. App bootstrap

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DragonflyApp(config: AppConfig()).init();
  runApp(const MyApp());
}
```

### 3. Build

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze     # the real pass/fail signal — never trust build_runner alone
```

> **Warning:** Nearly every generator swallows its own exceptions
> (`catch (e) { print(...); return ""; }`). `build_runner` reports `Succeeded`
> while writing an **empty or partial file**. `dart analyze` is always the
> gate. Grep the build log for `====>>` to find hidden crashes.

### 4. Verify

```bash
dart analyze
dart run build_runner build
```

Both commands must pass. Generated files are committed to the repo — comparing
`git diff` against the last known-good output is a fast way to catch silent
failures.

---

## Project layout

```
lib/
├── components/
│   ├── <component>/
│   │   ├── config/
│   │   │   ├── app_config.dart         DragonflyConfig subclass
│   │   │   ├── injector.dart           @InjectableInit anchor + .config.dart
│   │   │   └── injector.dragonfly.dart  component barrel (generated)
│   │   ├── data/
│   │   │   ├── models/                 @FactoryModel  → .model.dart
│   │   │   └── repositories/           @Repository    → .repository.dart
│   │   ├── domain/
│   │   │   ├── use_cases/              @UseCase       → .config.dart registration
│   │   │   └── forms/                  @FormSchema    → .form.dart
│   │   ├── exceptions/
│   │   └── presentation/
│   │       ├── states/                 @StateModel    → .state.dart
│   │       ├── features/               @StateManager  → .state_manager.dart
│   │       └── screens/                @Screen + @StateView → .view.dart
│   └── ...
├── config/
│   └── router_config.dart              @RouterConfig   → .router.dart
└── main.dart
```

---

## Models

`@FactoryModel` generates `fromJson`, optional `toJson`/`toMap`, `==`/`hashCode`,
`toString`, `copyWith`, and a contract interface. The `import` of
`package:dragonfly/dragonfly.dart` is mandatory — the generated part references
framework types and a part file cannot have its own imports.

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character.model.dart';

@FactoryModel(toJson: true, equals: true, toStringMethod: true, copyWith: true)
abstract interface class Character implements _$CharacterContract {
  factory Character({
    @Field(field: 'id')   required int id,
    required String name,
    required String status,
    required String species,
    required String image,
  }) = _$Character;

  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
```

| `@FactoryModel` option | Default | Effect |
|------------------------|---------|--------|
| `toJson`               | `true`  | Generate `Map<String, Object?> toJson()` |
| `toMap`                | `true`  | Generate `Map<String, Object?> toMap()` |
| `equals`               | `true`  | Generate `==` and `hashCode` |
| `toStringMethod`       | `true`  | Generate `toString()` |
| `copyWith`             | `false` | Generate a `copyWith` method |

`@Field(field: 'json_key')` renames the serialised key. `@Field(convertTo: 'type')`
wires a type converter. `@Field(ignore: true)` omits the field.

### DDD aggregates

`@Aggregate` on a `@FactoryModel` marks it as an aggregate root with a unique
identity. The generated class implements `AggregateRoot<T>` and gains identity-based
equality, `sameIdentityAs`, and an `isNew` getter — two entities with the same
identity are the same entity regardless of other state changes.

```dart
@FactoryModel(toJson: true)
@Aggregate(identityField: 'id')
abstract interface class Character implements _$CharacterContract {
  factory Character({
    required int id, required String name, required String status,
  }) = _$Character;
  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
```

Generated: `class _$Character implements FactoryModelWatcher, Character, AggregateRoot<int>`
with `int get identity => id`, `bool get isNew => id == null`,
`bool sameIdentityAs(Object other) => other is Character && id == other.id`, and
identity-based `==`/`hashCode`.

`@ValueObject()` marks a model as immutable and compared by all fields (no identity).
`@DomainEvent()` is a marker annotation for event records implementing
`DomainEvent`.

---

## Repositories

`@Repository` generates the HTTP (and realtime) client. Binding annotations wire
method parameters into the network call:

```dart
part 'character_repository.repository.dart';

@Repository(url: "character", realtimeConnection: "events")
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  /// GET character?name=...         — @Query → query string
  @Get()
  Future<ServiceResponse<Character>> getAll(@Query('name') String name);

  /// GET character/{id}             — @Path → URL placeholder substitution
  @Get(path: '/{id}')
  Future<Character> getById(@Path('id') int id);

  /// POST character + auth header   — @Body → toJson, @Authenticated → session token
  @Post()
  @Authenticated()
  Future<Character> createCharacter(@Body() Character character);

  /// WebSocket subscription        — one Character per frame
  @Subscribe(channel: "character.created")
  Stream<Character> onCharacterCreated();

  /// Batch subscription            — channel defaults to the method name
  @Subscribe()
  Stream<List<Character>> onCharacterBatch();
}
```

| Annotation | Binds to | Runtime behaviour |
|-----------|----------|-------------------|
| `@Path('name')` | URL placeholder `{name}` | `${name}` substitution in the path |
| `@Query('name')` | Query parameter `?name=` | `name` appears in the query string |
| `@Body()` | Request body | Calls `toJson()` on the parameter |
| `@Header(item:)` | Request header | Static `{key: value}` merged into headers |
| `@Authenticated()` | Session token | Resolves `'<conn>:authenticated'` adapter |

Network adapters (`DragonflyBaseNetworkAdapter`) are registered per connection name
through `DragonflyHttpAdapterConfig` (HTTP) and `DragonflyWebSocketAdapterConfig`
(WebSocket), or custom `DragonflyAdapterConfig` subclasses.

---

## Use cases

A use case is a plain class with a hand-written `call` method. The `@UseCase`
annotation triggers DI registration — no contract interface to implement.

```dart
@UseCase(instanceName: 'GetUserList')
class GetUserListUseCase {
  final CharacterRepository userRepository;
  const GetUserListUseCase(this.userRepository);

  Future<Either<Error, ServiceResponse<Character>>> call(String name) async {
    return Either.tryCatchAsync(
      () => userRepository.getAll(name),
      (error, _) => Error(),
    );
  }
}
```

### The `Either` type

`Either<L, R>` represents success or failure without exceptions. It is hand-written
in `framework/functional/either.dart` (no fpdart dependency):

```dart
final result = await useCase.call("Rick");

result.fold(
  (error)    => emit(CharacterState.error(message: error.toString())),
  (response) => emit(CharacterState.loaded(character: response.results.first)),
);

// Also available:
result.isRight / result.isLeft
result.getOrElse(defaultValue)
result.getOrElseCompute((left) => alt)
result.map((right) => transformed)
Either.tryCatch(() => riskySync())
Either.tryCatchAsync(() => riskyAsync())
```

In easy-mode state managers, a returned `Either<L, R>` is folded automatically:
`Right` becomes the payload variant, `Left` becomes `error`.

---

## States

`@StateModel` generates a sealed state class with pattern matching. Every factory
constructor becomes a variant subclass with `when`/`maybeWhen`, equality,
`hashCode` and `toString`:

```dart
part 'character_state.state.dart';

@StateModel()
sealed class CharacterState with _$CharacterState {
  const CharacterState._();
  const factory CharacterState.initial() = CharacterStateInitial;
  const factory CharacterState.loading() = CharacterStateLoading;
  const factory CharacterState.loaded({required Character character}) =
      CharacterStateLoaded;
  const factory CharacterState.characterList({
    required List<Character> characters,
  }) = CharacterStateCharacterList;
  const factory CharacterState.error({required String message}) =
      CharacterStateError;
}
```

The **zero-arg `initial` factory** is special — it becomes the controller's
starting state. Convention: a zero-arg `loading` factory enables automatic
loading emission before every event body runs; an `error({required String message})`
factory enables automatic error emission on thrown exceptions.

---

## State managers

State managers are the heart of the framework. They are **plain classes** — no base
class, no mixin, no hand-written `emit`. The generator wraps every `@StateManager` in
a `$XController extends DragonflyController<S>` that owns the state, is registered in
DI as a lazy singleton (with `dispose` wired), and wraps every `@Event` method with
automatic `loading`/`error` dispatching.

### StateModel mode — you design the state

```dart
part 'character_state_manager.state_manager.dart';

@StateManager(state: CharacterState, logging: true)
class CharacterStateManager {
  CharacterStateManager(@Inject('GetUserList') this._useCase);
  final GetUserListUseCase _useCase;

  @Event()
  Future<CharacterState> fetchCharacters() async {
    final result = await _useCase.call("Rick");
    return result.fold(
      (error)    => CharacterState.error(message: error.toString()),
      (response) => CharacterState.loaded(character: response.results.first),
    );
  }
}
```

**Rules for StateModel mode:**
- Every `@Event` returns the state type (or `Future` of it) — the returned value is
  emitted as-is. Never call `emit` by hand.
- The model **must** declare a zero-arg `initial` factory. If instead `initial` carries
  parameters (e.g., a form), provide an `initialState` getter on the delegate (see
  [Forms](#forms)).
- A zero-arg `loading` factory triggers automatic loading emission. An
  `error({required String message})` factory triggers automatic error emission on
  thrown exceptions.
- Constructor parameters are injected via DI; use `@Inject('name')` for named
  instances.

### Easy mode — the state is generated from your events

When `state:` is omitted, the sealed state class is generated from the `@Event`
methods. The method name becomes a variant, the return value becomes its `value`
payload. Built-in `initial`, `loading` and `error({required String message})`
variants are always present.

```dart
part 'character_search_state_manager.state_manager.dart';

@StateManager()
class CharacterSearchStateManager {
  CharacterSearchStateManager(@Inject('GetUserList') this._useCase);
  final GetUserListUseCase _useCase;

  @Event(debounce: Duration(milliseconds: 300))
  Future<List<Character>> search(String name) async { ... }

  @Event()
  Future<void> clear() async {}   // zero-payload variant
}
```

- `Future<T>` / `T` → `{required T value}` variant.
- `Future<Either<L, R>>` / `Either<L, R>` → R is the payload; L becomes `error`.
- `Future<void>` / `void` → zero-arg variant.
- A thrown exception becomes the `error` variant.

### Rate limiting — debounce & throttle

`@Event(debounce:)` and `@Event(throttle:)` are applied by the generated controller.
The view calls `search(query)` on every keystroke; the controller runs only the last
one within the window. Pending calls are cancelled when the controller is disposed.

```dart
@Event(debounce: Duration(milliseconds: 300))
Future<List<Character>> search(String name) async { ... }

@Event(throttle: Duration(seconds: 1))
Future<CharacterState> refreshThrottled() { ... }
```

### Plain methods

Public methods **without** `@Event` are forwarded by the controller untouched:
the view can call them and they emit no state.

```dart
Future<void> logAnalytics(String event) async { ... }
// view: logAnalytics('screen_view');
```

### What the generator produces

For `@StateManager class UserStateManager` the `.state_manager.dart` part contains:

- `$UserStateManagerController extends DragonflyController<UserStateManagerState>`
  — the DI singleton, wrapping the delegate.
- (easy mode only) `sealed class UserStateManagerState` with `when`/`maybeWhen`,
  variant subclasses with `==`/`hashCode`/`toString`.

For `@StateManager(state: CharacterState)` the state class is not generated — the
controller's start state is `const CharacterState.initial()`.

---

## Screens

Bind a widget to a manager with `@StateView` and mix in the generated `$Manager`
mixin. The whole API is flattened onto the widget — **no providers, no
`context.stateManager<T>()`**, no `StateManagerBuilder` — the controller lives in
DI and the mixin resolves it directly.

```dart
part 'character_screen.view.dart';

@Screen(path: '/', initial: true, name: 'characters', access: AccessLevel.guest)
@StateView(CharacterStateManager)
class CharacterScreen extends StatelessWidget with $CharacterStateManager {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: fetchCharacters),
      ]),
      body: when(
        loading: () => const CircularProgressIndicator(),
        loaded: (character) => Text(character.name),
        error: (message) => Text(message),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
```

### Mixin API

| Member | Purpose |
|--------|---------|
| `eventName(args)` | Dispatches an `@Event` — auto loading/error applied |
| `plainMethod(args)` | Forwards a plain method untouched |
| `currentState` | The synchronous current state (e.g., for init-dispatch) |
| `when({..., required orElse})` | Rebuilds on state change; every variant callback optional, `orElse` covers the rest |
| `build<Variant>(builder, {orElse})` | Typed builder — builds only while that variant is active |
| `buildFor('variant', (value) => ...)` | String-keyed escape hatch; `value` is `dynamic` |

**Payload rules for `buildFor`:** zero-field variants pass `null`, single-field pass
the field value, multi-field pass the variant object.

### Working on a StatefulWidget

The mixin has no `on` clause — it works on `StatelessWidget`, `StatefulWidget`'s
`State`, or any class:

```dart
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({super.key, @PathParam('id') required this.id});
  final int id;
  @override State<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen>
    with $CharacterStateManager {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchCharacter(widget.id));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: when(
        loaded: (c) => Text(c.name),
        loading: () => const CircularProgressIndicator(),
        error: (msg) => Text(msg),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
```

### Part & import requirements

The source file must:
1. `part 'name.view.dart';`
2. Import `package:flutter/widgets.dart` (for `Widget`, `SizedBox`)
3. Import `package:dragonfly/dragonfly.dart` (for `DragonflyStateBuilder`, `DragonflyContainer`)
4. Import the state manager file
5. (StateModel mode) Import the state model file

---

## Routing

`@RouterConfig` triggers the router generator. `@Screen` registers each route with
optional ACL:

```dart
@RouterConfig()
class AppRouterConfig with $AppRouterConfig {}
```

```dart
@Screen(path: '/login',            access: AccessLevel.guest)
class LoginScreen extends StatelessWidget { ... }

@Screen(path: '/home',             access: AccessLevel.authenticated)
class HomeScreen extends StatelessWidget { ... }

@Screen(path: '/admin',            access: AccessLevel.rolesRequired,
        roles: ['admin', 'superadmin'])
class AdminScreen extends StatelessWidget { ... }

@Screen(path: '/character/:id',    name: 'character-detail',
        access: AccessLevel.guest)
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({super.key, @PathParam('id') required this.id});
  final int id;
}
```

### Route parameters

`@PathParam` and `@QueryParam` on **constructor parameters** are extracted by the
generated router. Types `int`, `double` and `bool` are parsed automatically; `String`
is passed as-is. Query params are read from the URL query string.

### Wiring

```dart
class MyApp extends StatelessWidget {
  static final _router = AppRouterConfig();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: _router.initialRoute,
    );
  }
}
```

The generated router also produces `namedRoutes` for navigation (`/character/2`),
and `routeConfigs` with per-route ACL (`guest`/`authenticated`/`rolesRequired`/
`permissionsRequired`).

---

## Dependency injection

The DI container is a hand-written `get_it` replacement (`DragonflyContainer`,
`framework/di/`). It supports singleton, lazy-singleton, factory, async, factory-param,
scoped registrations, and a `reset()` method for tests.

### Registration (generated)

```dart
// components/<c>/config/injector.dart
import 'injector.config.dart';

@InjectableInit()
Future<void> initDragonflyContainer() async {
  DragonflyContainer.I.configureDependencies();
}
```

The generated `.config.dart` registers dependencies discovered by the visitor.
A `@StateManager` produces **two** registrations:

```dart
// Delegate — factory, re-resolved on each get
gh.registerFactory<CharacterStateManager>(
    () => CharacterStateManager(gh.get<GetUserListUseCase>(instanceName: 'GetUserList')));

// Controller — lazy singleton, shared across the app, disposed on scope pop
gh.registerLazySingleton<$CharacterStateManagerController>(
    () => $CharacterStateManagerController(gh.get<CharacterStateManager>()),
    dispose: (instance) => instance.dispose());
```

### Registering manually

```dart
DragonflyContainer.I.registerSingleton<MyService>(MyService());
DragonflyContainer.I.registerLazySingleton<MyRepo>(() => MyRepo());
DragonflyContainer.I.registerFactory<MyWidget>(() => MyWidget());
```

### Resolving

```dart
final svc = DragonflyContainer.I.get<MyService>();
final named = DragonflyContainer.I.get<MyService>(instanceName: 'alternative');
```

### Scopes

```dart
DragonflyContainer.I.pushNewScope();
// ... register scoped deps ...
await DragonflyContainer.I.popScope();   // disposes everything in the scope
```

Duplicates throw `DragonflyException` (get_it semantics). Set
`allowReassignment = true` to override.

---

## Configuration

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

---

## Component barrel

A barrel file is generated automatically next to each injector, re-exporting every
model, state, state manager, repository and form in the component:

```
lib/components/characters/config/injector.dragonfly.dart
```

One import pulls in the entire component:

```dart
import 'injector.dragonfly.dart';
```

Screens are excluded (their generated view mixins may conflict when several screens
bind the same manager). Consumers preferring individual imports override the
`component_generator` builder in `build.yaml`.

---

## Forms

`@FormSchema` generates a form state class (`LoginFormState`) with per-field typed
accessors, validation maps, and self-contained update methods.

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'login_form.form.dart';

@FormSchema()
class LoginForm {
  @Required(message: 'Email is required')
  @Email(message: 'Please enter a valid email address')
  final String email;

  @Required(message: 'Password is required')
  @MinLength(8)
  final String password;

  const LoginForm({this.email = '', this.password = ''});
}
```

### Generated API

```dart
LoginFormState form = LoginFormState.initial();

// Update a single field, validating when validateOnChange is on:
form = form.updateFieldValue('email', newEmail);

// Mark a field as touched, validating when validateOnBlur is on:
form = form.touchField('email');

// Validate everything and return the error-annotated state:
form = form.validateAllFields();
if (form.isValid) { ... }

// Typed accessors:
final emailField = form.email;     // DragonflyFormFieldState<String>
```

### Form-carrying state models

When the state model's `initial` variant carries the form, the manager must provide
an `initialState` getter (the generated controller cannot const-construct it):

```dart
part 'login_state.state.dart';

@StateModel()
sealed class LoginState with _$LoginState {
  const LoginState._();
  const factory LoginState.initial({required LoginFormState form}) = LoginStateInitial;
  const factory LoginState.editing({required LoginFormState form}) = LoginStateEditing;
  const factory LoginState.loading({required LoginFormState form}) = LoginStateLoading;
  const factory LoginState.success({required LoginFormState form}) = LoginStateSuccess;
  const factory LoginState.error({
    required LoginFormState form,
    required String message,
  }) = LoginStateError;
}
```

```dart
@StateManager(state: LoginState)
class LoginStateManager {
  LoginStateManager();
  LoginFormState _form = LoginFormState.initial();

  /// Called once by the generated controller instead of `const LoginState.initial()`.
  LoginState get initialState => LoginState.initial(form: _form);

  @Event()
  LoginState emailChanged(String value) {
    _form = _form.updateFieldValue('email', value);
    return LoginState.editing(form: _form);
  }
}
```

### Screen integration

```dart
/// Reads the form out of any [LoginState] variant.
LoginFormState _formOf(LoginState state) => state.when(
  initial: (f) => f, editing: (f) => f, loading: (f) => f,
  success: (f) => f, error: (f, _) => f,
);

// In the widget tree:
ValidatedTextField<LoginState>(
  stateController: _loginStateManagerController,
  fieldName: 'email',
  formSelector: _formOf,
  onChanged: emailChanged,
  ...
)
```

### Built-in validators

`@Required`, `@Email`, `@MinLength`, `@MaxLength`, `@Pattern`, `@Url`, `@Phone`,
`@Alphanumeric`, `@Alpha`, `@Numeric`, `@Min`, `@Max`, `@Range`, `@Positive`,
`@Negative`, `@EqualTo`, `@NotEqualTo`, `@PastDate`, `@FutureDate`, `@MinAge`,
`@MinItems`, `@MaxItems`, `@MustBeTrue`, `@MustBeFalse`, `@CreditCard`, `@Cvv`,
`@ExpiryDate`, `@StrongPassword`, `@RequiredIf`, `@RequiredUnless`, `@Custom`.

### Validated widgets

`ValidatedTextField<S>`, `ValidatedDropdown<S, T>`, `ValidatedCheckbox<S>`,
`ValidatedSwitch<S>`, `ValidatedDatePicker<S>`, `ValidatedSubmitButton<S>`,
`ValidatedForm`. Each takes `stateController`, `fieldName`, `formSelector` and
the relevant value-change callbacks. Error display is gated by `touched` by
default (change with `showErrorOnlyWhenTouched: false`).

---

## Sessions & ACL

```dart
await DragonflySessionManager.instance.init(
  config: const DragonflySessionConfiguration(
    loginPath: '/login',
    homePath: '/home',
    unauthorizedPath: '/unauthorized',
  ),
  storage: InMemorySessionStorage(),
);

await dragonflySession.login<User>(
  token: token,
  user: user,
  roles: ['admin'],
  permissions: ['read', 'write'],
);

if (dragonflySession.hasRole('admin')) { ... }
if (dragonflySession.hasPermission('write')) { ... }

await dragonflySession.logout();
```

The generated router calls `session.checkAccess(...)` before building every route.
Session tokens are injected into network requests by `AuthenticatedNetworkAdapter`
when a repository method carries `@Authenticated()`.

---

## Logging

`DragonflyLogManager.instance` provides structured logging with emoji icons,
duration tracking, request/response correlation IDs, and colourised output:

```dart
final log = DragonflyLogManager.instance;

log.info('User logged in', source: 'AuthManager', data: {'userId': 42});
log.error('Network timeout', error: e, stackTrace: s, source: 'Repo');
```

Generated repositories and controllers log automatically when the annotation
sets `logging: true`.

---

## Runtime primitives

### `DragonflyController<S>`

The base class for all generated controllers. You never subclass it directly.
Provides:
- `state` — the current state, read synchronously
- `stream` — broadcast stream backing every `DragonflyStateBuilder`
- `emit(S)` — `@protected`; only generated code calls it
- `schedule(key, body, {debounce, throttle})` — rate-limiting backed by `ActionScheduler`
- `dispose()` — idempotent; closes the stream, cancels pending actions
- `loggingEnabled` — overridden by the generated subclass when `logging: true`

### `DragonflyStateBuilder<S>`

The widget every generated view-mixin builder returns. Reads the controller's
current state synchronously on creation (first frame is real state, not a blank),
then rebuilds from the stream, gated by an optional `buildWhen`:

```dart
DragonflyStateBuilder<CharacterState>(
  controller: myController,
  buildWhen: (prev, curr) => prev is! CharacterStateLoading,
  builder: (context, state) => state.maybeWhen(
    loading: () => const Spinner(),
    orElse: () => const SizedBox.shrink(),
  ),
)
```

### `AggregateRoot<T>` (`framework/ddd/`)

The contract interface for aggregate-root entities. Generated `@Aggregate` models
implement this automatically: `T get identity`, `bool get isNew`, and
`bool sameIdentityAs(Object other)`.

### `AggregateRepository<T>`

Base repository contract with `findById`, `save`, and `delete`. Implement the
methods in your `@Repository` abstract class and the generator wires the calls —
`isNew` determines POST vs PUT for `save`.

### `DomainEvent`

Marker interface for domain event records.

---

## Annotations reference

### Models & data

| Annotation | What it does |
|-----------|-------------|
| `@FactoryModel(...)` | Generates fromJson, optional toJson/toMap/equals/copyWith |
| `@Field(field:, value:, convertTo:, ignore:)` | Customises a model property's serialisation |
| `@Aggregate(identityField:)` | Marks an aggregate root — identity-based equality, `sameIdentityAs`, `isNew`, `AggregateRoot<T>` |
| `@ValueObject()` | Marks an immutable value object |
| `@DomainEvent()` | Marks a domain event record |
| `@StateModel()` | Generates a sealed state with when/maybeWhen and variant classes |

### Repositories

| Annotation | What it does |
|-----------|-------------|
| `@Repository(url:, connection:, realtimeConnection:)` | Generates the HTTP/realtime repository impl |
| `@Get/@Post/@Put/@Patch/@Delete` | HTTP verb + optional path/headers |
| `@Path('name')` | URL placeholder → `${name}` substitution |
| `@Query('name')` | Query-parameter binding |
| `@Body()` | Request body — serialises a model via `toJson` |
| `@Header(item:)` | Static header map merged into the request |
| `@Subscribe(channel:)` | WebSocket subscription — method returns `Stream<T>` |
| `@Authenticated()` | Routes through the session-aware adapter |

### State management

| Annotation | What it does |
|-----------|-------------|
| `@StateManager()` / `@StateManager(state: X)` | Declares a state manager (easy / StateModel mode) |
| `@Event(debounce:, throttle:)` | State-emitting method — auto loading/error dispatching |
| `@StateView(Manager)` | Binds a widget to a state manager — generates the flattening mixin |

### DI & configuration

| Annotation | What it does |
|-----------|-------------|
| `@UseCase(instanceName:, env:, scope:, order:)` | DI registration for a use-case class |
| `@InjectableInit()` | Marks the DI init function — triggers `.config.dart` generation |
| `@Injectable(as:, env:, instanceName:)` | Registers a class as a factory |
| `@Singleton(as:, env:, instanceName:, signalsReady:, dependsOn:, dispose:)` | Registers as eager singleton |
| `@LazySingleton(as:, env:, instanceName:, dispose:)` | Registers as lazy singleton |
| `@Inject('name')` / `@Named('name')` | Named dependency on a constructor parameter |

### Routing

| Annotation | What it does |
|-----------|-------------|
| `@RouterConfig()` | Triggers router code generation |
| `@Screen(path:, name:, initial:, access:, roles:, permissions:)` | Registers a screen route with ACL |
| `@PathParam('name')` / `@QueryParam('name')` | Extracts a route/query parameter in a screen constructor |
| `@ScreenTransition` | Enum: `fade`, `slideRight`, `slideUp`, `scale`, `none`, `platform` |
| `@SessionConfig(...)` | Declarative session configuration |

### Forms

| Annotation | What it does |
|-----------|-------------|
| `@FormSchema(validateOnChange:, validateOnBlur:)` | Generates form state class + field enum |
| `@FormField(label:, hint:, keyboardType:, obscureText:)` | Field metadata for UI builders |
| `@Required/@Email/@MinLength/@MaxLength` | String validators |
| `@Pattern/@Url/@Phone/@Alphanumeric/@Alpha/@Numeric` | String format validators |
| `@Min/@Max/@Range/@Positive/@Negative` | Numeric validators |
| `@EqualTo/@NotEqualTo` | Comparison validators |
| `@PastDate/@FutureDate/@MinAge` | Date validators |
| `@MinItems/@MaxItems` | Collection validators |
| `@MustBeTrue/@MustBeFalse` | Boolean validators |
| `@CreditCard/@Cvv/@ExpiryDate` | Payment validators |
| `@StrongPassword` | Password strength validator |
| `@RequiredIf/@RequiredUnless` | Conditional validators |
| `@Custom` | Custom validation function |

---

## Generated files

| Extension | Input annotation | Content |
|-----------|-----------------|---------|
| `.model.dart` | `@FactoryModel` | Model impl, fromJson, toJson, equals, copyWith |
| `.state.dart` | `@StateModel` | Sealed state class, variants, when/maybeWhen |
| `.repository.dart` | `@Repository` | HTTP/realtime repository impl |
| `.state_manager.dart` | `@StateManager` | `$XController` + (easy mode) generated state class |
| `.view.dart` | `@StateView` | `$Manager` flattening mixin |
| `.form.dart` | `@FormSchema` | Form state class, field enum, validators |
| `.config.dart` | `@InjectableInit` | DI registration extension |
| `.router.dart` | `@RouterConfig` | Routes map, ACL config, onGenerateRoute |
| `.dragonfly.dart` | (component barrel) | Re-exports all generated sources in the component |

All generated files carry `// GENERATED CODE - DO NOT MODIFY BY HAND` and should
never be edited. Change the annotated source and rebuild.

---

## Build & verify

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

**The trap:** `build_runner` reports `Succeeded` even when a generator throws and
returns an empty file. The real error is buried in the build log (grep for `====>>`
and `error on`). Always verify with `dart analyze` and by reading the generated
file to confirm it contains real content, not just a header.

---

## Debugging

```dart
// Print every registered dependency across all scopes:
DragonflyContainer.I.debugPrintRegisteredInstances();

// Check a specific registration:
DragonflyContainer.I.isRegistered<MyService>(instanceName: 'alt');

// Verify async singletons are done:
await DragonflyContainer.I.allReady();
if (DragonflyContainer.I.allReadySync()) { ... }
```

### Missing dependency in `injector.config.dart`

If an annotated class does not appear in the generated config, another file in
`lib/` fails to compile. The DI scanner silently skips unresolvable libraries.
Fix that file, rebuild, and the dependency appears.

### Stale generated output

Generated files in this repo are committed. A stale file from a previous build
can mislead. Before drawing conclusions from one, regenerate with
`--delete-conflicting-outputs` and compare `git diff`.

---

## Troubleshooting

| Symptom | Cause |
|---------|-------|
| Generated file missing | Missing `part '…'` directive, or annotation not imported |
| Generated file empty | Generator threw; grep the build log for `====>>` / `error on` |
| Undefined name in a generated part | Source file is missing a required import (see per-annotation import requirements) |
| Dependency missing from `injector.config.dart` | Another file in `lib/` fails to compile — the scanner skips it silently |
| Duplicate registration exception | Same type+name registered twice. Set `allowReassignment = true` to override |
| `build_runner` reports success, `dart analyze` fails | Generators swallow exceptions — always analyze after building |
| `InvalidType` in generated code | Type declared in another generated file — rebuild once more (stale output) |
| `@View` not found / ambiguous | Use `@StateView` — Flutter exports its own `View` widget via `material` |
