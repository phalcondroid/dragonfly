---
name: dragonfly-app
description: Build features in a Flutter app that uses the Dragonfly framework — models, repositories, use cases, sealed states, state managers, screens, routing, and DI. Use whenever writing or modifying code in a project that depends on package:dragonfly, or when running its build_runner code generation.
---

# Writing app code with Dragonfly

Dragonfly replaces freezed + injectable + get_it + retrofit + bloc with one annotation set
and one generator suite. You write models, use cases, states, state managers, and screens;
everything else is generated.

**Philosophy:** every annotation and generated line exists to reduce your code.
If a pattern adds ceremony, it's wrong — the framework exists to make building
Flutter apps easier for both developers and AI agents.

## Non-negotiables

1. **Never hand-edit a generated file.** `*.model.dart`, `*.state.dart`,
   `*.repository.dart`, `*.form.dart`, `*.state_manager.dart`, `*.view.dart`,
   `*.config.dart`, `*.router.dart`. Change the annotated source and rerun the generator.
2. **Always regenerate, then analyze.**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   dart analyze
   ```
   `build_runner` reports success even when a generator failed and wrote an empty file.
   `dart analyze` is the real check.
3. **State management is v2 only.** `@StateManager` on a plain class, `@Event` methods
   that return values, `@StateView(Manager)` widgets with the generated `$Manager`
   mixin. The old stack (`StateManager<S>`, `Feature`, `@StateAction`, `StateScope`,
   bloc types) was deleted — do not use it. Annotations are unprefixed: `@UseCase`,
   `@Screen`, `@RouterConfig`, `@InjectableInit` (the `Dragonfly`-prefixed aliases still
   work but are deprecated).

---

## Folder layout

One folder per component, four layers:

```
lib/components/<component>/
├── config/          injector.dart
├── data/
│   ├── models/      @FactoryModel
│   └── repositories/@Repository
├── domain/
│   └── use_cases/   @UseCase
└── presentation/
    ├── states/      @StateModel (optional — only for StateModel mode)
    ├── features/    @StateManager
    └── screens/     @Screen + @StateView
```

---

## Models

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character.model.dart';

@FactoryModel(toJson: true, toMap: true, equals: true, toStringMethod: true, copyWith: true)
abstract interface class Character implements _$CharacterContract {
  factory Character({
    @Field(field: "id", value: 0) required int id,
    required String name,
    required String status,
  }) = _$Character;

  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
```

The `import 'package:dragonfly/dragonfly.dart';` is **required** — the generated part
references framework types and a part file cannot declare its own imports.

Generic models add `generic: true` and a converter parameter on `fromJson`:

```dart
@FactoryModel(generic: true, toJson: true, toMap: true, equals: true, toStringMethod: true)
abstract interface class ServiceResponse<T> implements _$ServiceResponseContract<T> {
  factory ServiceResponse({required Info info, required List<T> results}) = _$ServiceResponse;

  factory ServiceResponse.fromJson(
    Map<String, Object?> value,
    T Function(Object? json) fromJsonT,
  ) = _$ServiceResponse.fromJson;
}
```

`@Field` options: `field` (JSON key), `value` (default), `converTo`, `ignore`, `fromJson`,
`toJson`.

---

## Repositories

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part "character_repository.repository.dart";

@Repository(url: "character")
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  @Get()
  Future<ServiceResponse<Character>> getAll();
}
```

The `factory X() = _X;` line is required — it is how callers reach the generated impl.
Repositories are auto-registered as **lazy singletons**.

### Limitation you must not paper over

**Request parameters are not implemented.** `@Path`, `@Query`, `@Body`, and `@Header`
exist but no generator reads them. The emitted call is always:

```dart
await network.callForObject(HttpMethods.get, '<url><path>', null, null);
```

So there is no path substitution, no query string, and no request body. If a feature needs
those, say so plainly and either hand-write that repository method against
`DragonflyNetworkHttpAdapter`, or raise it as framework work. Do not annotate `@Query()`
and imply it works.

Multiple backends: add `DragonflyInstanceConfig` entries with distinct `connectionName`s
and reference them via `@Repository(connection: 'name')`.

### Realtime subscriptions

Unlike the HTTP path, `@Subscribe` is fully wired. Return a `Stream` and annotate:

```dart
@Repository(url: "character", realtimeConnection: "events")
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  @Subscribe(channel: "character.created")
  Stream<Character> onCharacterCreated();

  /// Channel defaults to the method name.
  @Subscribe()
  Stream<List<Character>> onCharacterBatch();
}
```

Register the transport in your `DragonflyConfig`:

```dart
@override
List<DragonflyRealtimeInstanceConfig> get realtimeConfigs => [
  const DragonflyRealtimeInstanceConfig(
    connectionName: "events",
    config: DragonflyRealtimeConfig(url: "wss://api.example.com/ws"),
  ),
];
```

The default envelope is `{"action": ..., "channel": ..., "data": {...}}`; override
`channelField` / `dataField` / `actionField` to match your backend, or set
`channelField: null` for a server that emits bare payloads on a per-resource URL.

The socket opens lazily on first `listen`, reconnects with exponential backoff, and
replays subscriptions after a drop.

Consume a stream from a state manager using `subscribe`, which ties the subscription to
the manager's lifecycle:

```dart
@override
void onInit() {
  subscribe('created', _repository.onCharacterCreated(),
      onData: (character) => emit(CharacterState.loaded(character: character)));
}
```

---

## Use cases

```dart
@UseCase(instanceName: 'GetUserList')
class GetUserListUseCase {
  final CharacterRepository userRepository;
  const GetUserListUseCase(this.userRepository);

  Future<Either<Error, ServiceResponse<Character>>> call(String name) async {
    return Either.tryCatchAsync(
      () => userRepository.getAll(),
      (error, stackTrace) => Error(),
    );
  }
}
```

Registered as a **factory**. A use case is a plain class with a hand-written `call`
method — there is no contract interface (the old `UseCase` contract was deleted; the
name belongs to the annotation).

`Either`: `fold(onLeft, onRight)`, `isLeft`/`isRight`, `getOrElse(value)`,
`getOrElseCompute(fn)`, `Either.tryCatch`, `Either.tryCatchAsync`, `Either.fromNullable`.
Note `getOrElse` takes a **value**, not a callback.

---

## States

```dart
part 'character_state.state.dart';

@StateModel()
sealed class CharacterState with _$CharacterState {
  const CharacterState._();

  const factory CharacterState.initial() = CharacterStateInitial;
  const factory CharacterState.loading() = CharacterStateLoading;
  const factory CharacterState.loaded({required Character character}) = CharacterStateLoaded;
  const factory CharacterState.error({required String message}) = CharacterStateError;
}
```

Generates `when`, `maybeWhen`, `map`, `maybeMap`, equality, and `toString`.

**Design the variants carefully** — the view generator produces one typed
`build<Variant>` builder per variant, which is where most of the boilerplate savings
come from. Declare a zero-arg `initial` factory if you bind a `@StateManager(state:)`
to this model; `loading` and `error({required String message})` factories enable
automatic loading/error emission.

---

## State managers

A state manager is a **plain class** — no base class, no mixin, no `emit`. The
generator wraps it in a `$XController` that owns the state and is registered in DI as a
lazy singleton.

### StateModel mode — you design the state

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character_state_manager.state_manager.dart';

@StateManager(state: CharacterState, logging: true)
class CharacterStateManager {
  CharacterStateManager(@Inject('GetUserList') this._useCase);

  final GetUserListUseCase _useCase;

  @Event()
  Future<CharacterState> fetchCharacters() async {
    final result = await _useCase.call("Rick");
    return result.fold(
      (error) => CharacterState.error(message: error.toString()),
      (response) => CharacterState.loaded(character: response.results.first),
    );
  }
}
```

Rules:

- Every `@Event` returns the state type (or `Future` of it); the returned value is
  emitted. Plain public methods (no `@Event`) are callable from the view but emit
  nothing.
- The model must declare a zero-arg `initial` factory — the starting state.
- If the model declares zero-arg `loading`, it is emitted automatically before every
  event body runs. If it declares `error({required String message})`, a thrown
  exception is emitted through it.
- Constructor parameters are injected; `@Inject('name')` resolves a named instance.

### Easy mode — the state is generated for you

```dart
part 'character_search_state_manager.state_manager.dart';

@StateManager()
class CharacterSearchStateManager {
  CharacterSearchStateManager(@Inject('GetUserList') this._useCase);
  final GetUserListUseCase _useCase;

  @Event(debounce: Duration(milliseconds: 300))
  Future<List<Character>> search(String name) async { ... }

  @Event()
  Future<void> clear() async {}
}
```

The method name becomes a variant of the generated
`CharacterSearchStateManagerState`, and the return value becomes its `value` payload
(`Future<void>` → zero-payload variant). Built-in `initial`, `loading`, and `error`
variants always exist. A thrown exception becomes `error`; a returned
`Either<L, R>` is folded — `Right` is the payload, `Left` becomes `error`.

### Rate limiting

`@Event(debounce: …)` / `@Event(throttle: …)` are applied by the generated controller —
the view just calls `search(query)` on every keystroke. Pending calls are cancelled
when the controller is disposed.

---

## Screens

Bind a screen to a manager with `@StateView` and mix in the generated `$Manager`
mixin — the whole API is flattened onto the widget. **No provider wrapping, no
`context.stateManager<T>()`** — the controller resolves from DI. The
`stateManager:` parameter on `@Screen` triggers the view generator automatically —
no separate `@StateView` annotation is needed on screen widgets.

```dart
part 'character_screen.view.dart';

@Screen(path: '/', initial: true, name: 'characters',
       stateManager: CharacterStateManager, access: AccessLevel.guest)
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

What the mixin gives you:

- **Dispatchers** — call events directly: `fetchCharacters()`, `search(query)`.
- **`currentState`** — the synchronous current state, useful for reading state
  outside a builder (e.g., in `initState` of a `StatefulWidget`'s `State` class
  that mixes in `$Manager`).
- **`when({..., required orElse})`** — rebuilds on every state change; every variant
  callback is optional, `orElse` covers the rest.
- **Typed `build<Variant>(builder, {orElse})`** — one per variant
  (`buildLoaded((character) => ...)`); builds only while that variant is active.
  Prefer these over a single big `when` for overlay-style layouts.
- **`buildFor('variant', (value) => ...)`** — the string-keyed escape hatch; payload is
  `dynamic` (single-field variants pass the field, zero-field pass `null`, multi-field
  pass the state object).

The file must `part 'name.view.dart';` and import Flutter widgets,
`package:dragonfly/dragonfly.dart`, the state manager file, and (StateModel mode) the
state model file. Several screens can bind the same manager — each file gets one
`$Manager` mixin.

---

## Component barrel

A barrel file is generated automatically next to the injector, re-exporting every
model, state, state manager, repository and form in the component:

```
lib/components/characters/config/injector.dragonfly.dart
```

A single import brings in the entire component's public API:

```dart
import 'injector.dragonfly.dart';
```

The barrel skips screens (their generated view mixins may conflict when several
screens bind the same `@StateManager`). Consumers who prefer importing individual
generated files simply override the `component_generator` builder in their
`build.yaml` with `generate_for: []`.

---

## Routing

```dart
@Screen(
  path: '/character',
  name: 'characters',
  initial: true,
  access: AccessLevel.authenticated,
)
class CharacterScreen extends StatelessWidget { … }
```

```dart
@RouterConfig()
class AppRouterConfig with $AppRouterConfig {}
```

```dart
MaterialApp(
  onGenerateRoute: _router.onGenerateRoute,
  initialRoute: _router.initialRoute,
);
```

There is no `provider:` parameter in v2 — the view mixin resolves the controller from
DI, so routes never wrap. `access:` is enforced through
`DragonflySessionManager.checkAccess`. `AccessLevel` values: `guest`, `authenticated`,
`rolesRequired`, `permissionsRequired`.

`@PathParam` / `@QueryParam` are applied to **constructor parameters** of the screen:

```dart
@Screen(path: '/character/:id', name: 'character-detail', access: AccessLevel.guest)
@StateView(CharacterStateManager)
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({super.key, @PathParam('id') required this.id});
  final int id;
  ...
}
```

The generated router extracts the matched path segment and passes it to the
constructor. Types `int`, `double` and `bool` are parsed automatically; `String`
is passed as-is. Query params are read from the query string via the same
mechanism.

---

## Wiring it up

```dart
// components/<c>/config/injector.dart
part 'injector.config.dart';

@InjectableInit()
Future<void> initDragonflyContainer() async {
  DragonflyContainer.I.configureDependencies();
}
```

```dart
class AppConfig extends DragonflyConfig {
  @override
  List<DragonflyInstanceConfig> get instanceConfigs => [
    const DragonflyInstanceConfig(
      options: DragonflyHttpBaseOptions(baseUrl: "https://api.example.com/"),
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

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DragonflyApp(config: AppConfig()).init();
  runApp(const MyApp());
}
```

Six annotations are scanned for DI: `@UseCase`, `@Repository`, `@StateManager`,
`@Injectable`, `@Singleton`, and `@LazySingleton`. A `@StateManager` produces **two**
entries (the delegate factory and the controller lazy singleton with `dispose`).
Registrations carry `as`, `env`, `scope`, `order`, and `instanceName` support.

Debug DI with `DragonflyContainer.I.debugPrintRegisteredInstances()`. Registering
the same type+name twice **throws** `DragonflyException`. Set `allowReassignment = true`
to override.

---

## Sessions and ACL

```dart
await DragonflySessionManager.instance.init(
  config: const DragonflySessionConfiguration(
    loginPath: '/login', homePath: '/home', unauthorizedPath: '/unauthorized',
  ),
  storage: InMemorySessionStorage(),
);

await dragonflySession.login<User>(token: t, user: u, roles: ['admin'], permissions: ['read']);
if (dragonflySession.hasRole('admin')) { … }
await dragonflySession.logout();
```

`@DragonflySessionConfig` as an annotation is not read; configure at runtime as above.

---

## Forms

```dart
@FormSchema()
class LoginForm {
  @Required(message: 'Email is required')
  @Email(message: 'Please enter a valid email')
  final String email;

  @Required(message: 'Password is required')
  @MinLength(8)
  final String password;

  const LoginForm({this.email = '', this.password = ''});
}
```

Generates `LoginFormState` with per-field validation. The form state is
self-contained:

```dart
LoginFormState form = LoginFormState.initial();

// Update a field value (validates when validateOnChange is on):
form = form.updateFieldValue('email', newEmail);

// Mark a field as touched (validates when validateOnBlur is on):
form = form.touchField('email');

// Validate everything at once:
form = form.validateAllFields();
if (form.isValid) { ... }
```

### Form state inside a state manager

When the `@StateModel`'s `initial` variant carries parameters (e.g., the form),
the manager must expose an `initialState` getter because the generated controller
cannot const-construct it:

```dart
@StateManager(state: LoginState)
class LoginStateManager {
  LoginStateManager();

  LoginFormState _form = LoginFormState.initial();

  /// The controller calls this instead of `const LoginState.initial()`.
  LoginState get initialState => LoginState.initial(form: _form);

  @Event()
  LoginState emailChanged(String value) {
    _form = _form.updateFieldValue('email', value);
    return LoginState.editing(form: _form);
  }
}
```

Screen widgets reference the form through a selector function:

```dart
LoginFormState _formOf(LoginState state) => state.when(
  initial: (form) => form,
  editing: (form) => form,
  loading: (form) => form,
  success: (form) => form,
  error: (form, _) => form,
);

// In the widget:
ValidatedTextField<LoginState>(
  stateController: _loginStateManagerController,
  fieldName: 'email',
  formSelector: _formOf,
  onChanged: emailChanged,
  ...
)
```

---

## Troubleshooting

| Symptom | Cause |
| ------- | ----- |
| Generated file missing | Missing `part '…';` directive, or annotation not imported |
| Generated file empty | Generator threw; grep the build log for `====>>` |
| Undefined name in a generated part | Source file is missing `import 'package:dragonfly/dragonfly.dart';` (and the state model / manager file for `@StateView` parts) |
| Dependency missing from `injector.config.dart` | Another file in `lib/` fails to compile — the DI scanner skips unresolvable libraries silently. Fix that first |
| Route missing from generated router | Same cause as above |
| `Object of type X with name null not found` | Not registered, or registered under a different `instanceName` |
