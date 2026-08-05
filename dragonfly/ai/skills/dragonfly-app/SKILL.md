---
name: dragonfly-app
description: Build features in a Flutter app that uses the Dragonfly framework — models, repositories, use cases, sealed states, state managers, screens, routing, and DI. Use whenever writing or modifying code in a project that depends on package:dragonfly, or when running its build_runner code generation.
---

# Writing app code with Dragonfly

Dragonfly replaces freezed + injectable + get_it + retrofit + bloc with one annotation set
and one generator suite. You write models, use cases, states, state managers, and screens;
everything else is generated.

## Non-negotiables

1. **Never hand-edit a generated file.** `*.model.dart`, `*.state.dart`, `*.event.dart`,
   `*.repository.dart`, `*.form.dart`, `*.state_manager.dart`, `*.config.dart`,
   `*.router.dart`. Change the annotated source and rerun the generator.
2. **Always regenerate, then analyze.**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   dart analyze
   ```
   `build_runner` reports success even when a generator failed and wrote an empty file.
   `dart analyze` is the real check.
3. **Use `StateManager`, never `Feature`.** `Feature`, `@DragonflyFeature`,
   `@DragonflyView`, `@ViewAction`, `FeatureBuilder`, and `context.feature<T>()` are
   deprecated aliases.

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
│   └── use_cases/   @InjectableUseCase
└── presentation/
    ├── states/      @StateModel
    ├── features/    @DragonflyStateManager
    └── screens/     @DragonflyScreen
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
@InjectableUseCase(instanceName: 'GetUserList')
class GetUserListUseCase
    implements UseCase<Map<String, dynamic>, Error, ServiceResponse<Character>> {
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

Registered as a **factory**. `UseCase` enforces no `call` signature — for a checked one,
implement `UseCaseWithParams<Params, Error, Response>` or `UseCaseNoParams<Error, Response>`.

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

**Design the variants carefully** — the state manager generator produces one builder
widget per variant, which is where most of the boilerplate savings come from.

---

## State managers

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:flutter/material.dart';

part 'character_feature.state_manager.dart';

@DragonflyStateManager(logging: true)
class CharacterFeature extends StateManager<CharacterState>
    with _$CharacterFeatureMixin {
  CharacterFeature(@Inject('GetUserList') this._useCase)
      : super(const CharacterState.initial());

  final GetUserListUseCase _useCase;

  @StateAction()
  Future<void> fetchCharacters() async {
    emit(const CharacterState.loading());
    final result = await _useCase.call("Rick");
    result.fold(
      (error) => emit(CharacterState.error(message: error.toString())),
      (response) => emit(CharacterState.loaded(character: response.results.first)),
    );
  }
}
```

Both `package:dragonfly/dragonfly.dart` and `package:flutter/material.dart` imports are
required — the generated part contains widgets.

Registered as a **factory**. `@Inject('name')` on a constructor parameter resolves a named
instance.

Available from `StateManager`: `emit`, `sideEffect`, `state`, `stream`, `subscribe(key,
stream, onData:)`, `cancelSubscription`, `useCase<T>()`, `get<T>()`, `onInit`, `onDispose`,
and the manual log helpers `logActionStart` / `logStep` / `logActionEnd`.

### What `@StateAction` does and does not do

`debounce:` and `throttle:` **work**. The generator emits an `actions` façade:

```dart
@StateAction(debounce: Duration(milliseconds: 300))
Future<void> searchByName(String name) async { ... }
```

```dart
// debounced — use this from a TextField's onChanged
feature.actions.searchByName(query);

// immediate — the method itself is unchanged
feature.searchByName(query);
```

Pending calls are cancelled when the manager is disposed. `actions.<name>(...)` returns
`false` when a throttle gate dropped the call.

A bare `@StateAction()` with no policy generates nothing — the method is called directly.
`@Computed()` also generates nothing; write the getter by hand (it works, it is just not
generated). `@SideEffect()` and `@StateSlot()` are never read at all.

Side effects work through the runtime call, not the annotation:

```dart
sideEffect(const ShowSnackbar('Saved'));
sideEffect(const NavigateTo('/home'));
```

Wrap the screen in `StateScope<CharacterFeature>` and they are handled for you.

---

## Screens

Wrap a screen in `StateScope<SM>` — one widget that resolves the manager from DI, provides
it, applies side effects, and disposes it:

```dart
StateScope<CharacterFeature>(
  child: const CharacterScreen(),
)
```

Then extend `StateView<SM, S>` to receive the state and the manager directly:

```dart
class CharacterScreen extends StateView<CharacterFeature, CharacterState> {
  const CharacterScreen({super.key});

  @override
  Widget buildState(BuildContext context, CharacterState state,
      CharacterFeature manager) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: manager.fetchCharacters,
        ),
      ]),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const CircularProgressIndicator(),
        loaded: (character) => Text(character.name),
        characterList: (characters) => Text('${characters.length}'),
        error: (message) => Text(message),
      ),
    );
  }
}
```

Override `buildWhen(previous, current)` to skip rebuilds, and use `StateSelector` for a
subtree that depends on one slice:

```dart
StateSelector<CartFeature, CartState, int>(
  selector: (state) => state.items.length,
  builder: (context, count) => Badge(count: count),
)
```

### Per-variant builder widgets

Also generated for you, one per state variant:

```dart
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feature = context.stateManager<CharacterFeature>();

    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: feature.fetchCharacters),
      ]),
      body: Column(children: [
        CharacterLoading(builder: () => const CircularProgressIndicator()),
        CharacterLoaded(builder: (character) => Text(character.name)),
        CharacterError(builder: (message) => Text(message)),
      ]),
    );
  }
}
```

`CharacterLoading` / `CharacterLoaded` / `CharacterError` are generated from the state
variants — **prefer these over a manual `state.when(...)`**. Each accepts `buildWhen` and
`orElse`.

Also generated: `CharacterFeatureProvider` (resolves from DI) and
`context.characterFeature`.

For lower-level control: `StateManagerBuilder`, `StateManagerListener`,
`StateManagerConsumer`, `StateManagerSelector`, `StateManagerSideEffectListener`.

---

## Routing

```dart
@DragonflyScreen(
  path: '/character',
  name: 'characters',
  initial: true,
  access: AccessLevel.authenticated,
  provider: CharacterFeature,
)
class CharacterScreen extends StatelessWidget { … }
```

```dart
@DragonflyRouterConfig()
class AppRouterConfig with $AppRouterConfig {}
```

```dart
MaterialApp(
  onGenerateRoute: _router.onGenerateRoute,
  initialRoute: _router.initialRoute,
);
```

`provider:` wraps the route in that state manager's generated provider. `access:` is
enforced through `DragonflySessionManager.checkAccess`. `AccessLevel` values: `guest`,
`authenticated`, `rolesRequired`, `permissionsRequired`.

`@PathParam` / `@QueryParam` exist but are **not implemented** — read route arguments from
`RouteSettings` instead.

---

## Wiring it up

```dart
// components/<c>/config/injector.dart
part 'injector.config.dart';

@DragonflyInjectableInit()
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

Only `@InjectableUseCase`, `@Repository`, `@DragonflyStateManager`, and `@DragonflyBloc`
are scanned for DI. **`@Singleton`, `@LazySingleton`, and `@Injectable` are never
registered** — register those manually on `DragonflyContainer.I`.

Debug DI with `DragonflyContainer.I.debugPrintRegisteredInstances()`. Note that
registering the same type+name twice is a **silent no-op**, not an error.

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

## Forms — currently unusable

`@FormSchema` and its validators generate code that **does not compile**: the generated
state class is named `<Class>FormState` (so `LoginForm` yields `LoginFormFormState`), the
generated part references framework types the source file must import manually, and
`FormFieldState` collides with Flutter's `FormFieldState`.

Do not build features on `@FormSchema` yet. Use plain `TextEditingController`s and manual
validation, and flag the gap.

---

## Troubleshooting

| Symptom | Cause |
| ------- | ----- |
| Generated file missing | Missing `part '…';` directive, or annotation not imported |
| Generated file empty | Generator threw; grep the build log for `====>>` |
| Undefined name in a generated part | Source file is missing `import 'package:dragonfly/dragonfly.dart';` (and `material.dart` for state managers) |
| Dependency missing from `injector.config.dart` | Another file in `lib/` fails to compile — the DI scanner skips unresolvable libraries silently. Fix that first |
| Route missing from generated router | Same cause as above |
| `Object of type X with name null not found` | Not registered, or registered under a different `instanceName` |
