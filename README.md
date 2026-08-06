# Dragonfly Framework

A Flutter framework that replaces the usual stack (freezed, injectable, get_it, retrofit,
bloc, fpdart) with one annotation set and one code generator suite, so app authors write
only models, use cases, state managers and screens — everything else is generated.

## Packages

| Package | Role |
|---------|------|
| `dragonfly` | Runtime: DI container, network, state management, session, logging |
| `dragonfly_annotations` | Annotation classes only — no logic |
| `dragonfly_builder` | `source_gen` builders that read those annotations |

Dependency direction:
```
dragonfly_builder ──▶ dragonfly_annotations ◀── dragonfly
                                                    ▲
example ────────────────────────────────────────────┘
```

---

## Quick start

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

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze                         # the real pass/fail — not build_runner
```

> `build_runner` reports success even when a generator wrote an empty file.
> Always analyze after generating.

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DragonflyApp(config: AppConfig()).init();
  runApp(const MyApp());
}
```

---

## Component layout

```
lib/components/<component>/
├── config/          injector.dart   (@InjectableInit) + generated injector.config.dart
├── data/
│   ├── models/      @FactoryModel   → .model.dart
│   └── repositories/@Repository     → .repository.dart
├── domain/
│   └── use_cases/   @UseCase        → .config.dart DI registration
└── presentation/
    ├── states/      @StateModel     → .state.dart (StateModel mode only)
    ├── features/    @StateManager   → .state_manager.dart
    └── screens/     @Screen + @StateView → .view.dart
```

---

## Models

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character.model.dart';

@FactoryModel(toJson: true, equals: true, toStringMethod: true, copyWith: true)
abstract interface class Character implements _$CharacterContract {
  factory Character({
    @Field(field: 'id') required int id,
    required String name,
    required String status,
    required String species,
    required String image,
  }) = _$Character;

  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
```

The `import 'package:dragonfly/dragonfly.dart';` is required — the generated part
references framework types and a part file cannot have its own imports.

---

## Repositories

```dart
part 'character_repository.repository.dart';

@Repository(url: "character")
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  @Get()
  Future<ServiceResponse<Character>> getAll(@Query('name') String name);

  @Get(path: '/{id}')
  Future<Character> getById(@Path('id') int id);

  @Post()
  @Authenticated()
  Future<Character> createCharacter(@Body() Character character);
}
```

Binding annotations work: `@Path` substitutes URL placeholders, `@Query` appends query
parameters, `@Body` serializes a model through `toJson`, and `@Header` merges static
headers. `@Authenticated` routes through the session-aware adapter (registered under
`'<name>:authenticated'`).

Returning `Stream<T>` / `Stream<List<T>>` generates realtime subscriptions via
`@Subscribe` (websocket-backed).

---

## Use cases

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

A use case is a plain class with a hand-written `call` method. No contract interface —
the `@UseCase` annotation handles DI registration.

---

## States

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

Generates `when`, `maybeWhen`, equality, `hashCode` and `toString` on every variant.

---

## State managers

State managers are **plain classes** — no base class, no mixin, no hand-written `emit`.
The generator produces a `$XController extends DragonflyController<S>` that owns the
state and is registered in DI as a lazy singleton.

### StateModel mode — you design the state model

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
      (error) => CharacterState.error(message: error.toString()),
      (response) => CharacterState.loaded(character: response.results.first),
    );
  }
}
```

Rules:
- Every `@Event` returns the state type (or `Future` of it); the returned value is
  **emitted as-is**.
- The model must declare a zero-arg `initial` factory — the controller's starting state.
- If the model also declares a zero-arg `loading` factory, it is emitted automatically
  before every event body runs. If it declares `error({required String message})`, a
  thrown exception is emitted through it.
- Constructor parameters are injected via DI; `@Inject('name')` resolves a named instance.

### Easy mode — the state is generated from your events

```dart
part 'character_search_state_manager.state_manager.dart';

@StateManager()
class CharacterSearchStateManager {
  CharacterSearchStateManager(@Inject('GetUserList') this._useCase);
  final GetUserListUseCase _useCase;

  @Event(debounce: Duration(milliseconds: 300))
  Future<List<Character>> search(String name) async { ... }
}
```

The method name becomes a state variant; the return value becomes its payload
(`Future<void>` → zero-payload variant). Built-in `initial`, `loading` and
`error({required String message})` variants are always present. A thrown exception
becomes `error`; a returned `Either<L,R>` is folded (Right is the payload, Left becomes
`error`).

### Rate limiting

`@Event(debounce:)` and `@Event(throttle:)` are applied by the generated controller.
The view calls `search(query)` on every keystroke; the controller runs only the last one
within the window.

---

## Screens

Bind a screen to a manager with `@StateView` and mix in the generated `$Manager`
mixin — the whole API is flattened onto the widget. **No providers, no context-resolved
managers** — the controller lives in DI.

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

What the mixin provides:
- **Dispatchers** — call events directly: `fetchCharacters()`, `search(query)`.
- **`when({..., required orElse})`** — all variant callbacks optional; `orElse` covers unmatched ones.
- **Typed `build<Variant>(builder, {orElse})`** — one per variant (`buildLoaded((c) => ...)`).
- **`buildFor('variant', (value) => ...)`** — string-keyed escape hatch; payload is `dynamic`.
- **`currentState`** — the synchronous current state.

The view mixin also works on `StatefulWidget`'s `State` class — use it in `initState` to
dispatch events once.

---

## Routing

```dart
@Screen(path: '/character/:id', name: 'character-detail', access: AccessLevel.guest)
@StateView(CharacterStateManager)
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({super.key, @PathParam('id') required this.id});
  final int id;
  ...
}
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

`@PathParam` and `@QueryParam` on constructor parameters are extracted from the URL by
the generated router. Access control (`AccessLevel.guest` / `authenticated` /
`rolesRequired` / `permissionsRequired`) is enforced by the generated `onGenerateRoute`.

---

## Dependency injection

```dart
// components/<c>/config/injector.dart
import 'injector.config.dart';

@InjectableInit()
Future<void> initDragonflyContainer() async {
  DragonflyContainer.I.configureDependencies();
}
```

Only `@UseCase`, `@Repository`, `@StateManager` and `@Singleton`/`@LazySingleton`/
`@Injectable` are scanned for DI registration. A `@StateManager` produces **two**
registrations: the delegate (factory) and the generated `$XController` (lazy singleton
with `dispose` wired).

---

## Configuration

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

Authentication-aware adapters are registered automatically under
`'<connectionName>:authenticated'` for every connection.

---

## Component barrel (optional)

A per-component barrel is generated automatically next to the injector file:

```
lib/components/characters/config/injector.dragonfly.dart
```

A single `import 'injector.dragonfly.dart';` pulls in every model, state, state manager,
repository and form in the component. The barrel skips screens (their generated view
mixins may conflict with the same manager bound to multiple screens).

Consumers that prefer importing individual generated files simply override the
`component_generator` builder in their `build.yaml`.

---

## Forms

```dart
@FormSchema()
class LoginForm {
  @Required(message: 'Email is required')
  @Email(message: 'Please enter a valid email address')
  final String email;

  @Required(message: 'Password is required')
  @MinLength(8, message: 'Password must be at least 8 characters')
  final String password;

  const LoginForm({this.email = '', this.password = ''});
}
```

Generates `LoginFormState extends FormController` with per-field validation,
`updateFieldValue`, `touchField` and `validateAllFields` methods.

The generated form state is self-contained — use it inside a `@StateManager` delegate
and emit form-carrying state variants:

```dart
@StateManager(state: LoginState)
class LoginStateManager {
  LoginStateManager();
  LoginFormState _form = LoginFormState.initial();
  LoginState get initialState => LoginState.initial(form: _form);

  @Event()
  LoginState emailChanged(String value) {
    _form = _form.updateFieldValue('email', value);
    return LoginState.editing(form: _form);
  }
}
```

Screen widgets reference the form through `formSelector: _formOf`:

```dart
ValidatedTextField<LoginState>(
  stateController: _loginStateManagerController,
  fieldName: 'email',
  formSelector: _formOf,
  onChanged: emailChanged,
  ...
)
```

---

## Debugging

```dart
DragonflyContainer.I.debugPrintRegisteredInstances();
```

If a dependency is missing from the generated `injector.config.dart`, another file in
`lib/` fails to compile — the DI scanner silently skips unresolvable libraries. Fix that
file first, rebuild, and the dependency appears.

---

## Session and ACL

```dart
await DragonflySessionManager.instance.init(
  storage: InMemorySessionStorage(),
);
await dragonflySession.login<User>(token: t, user: u, roles: ['admin']);
if (dragonflySession.hasRole('admin')) { ... }
```

---

## Annotations reference

| Annotation | What it does |
|-----------|-------------|
| `@FactoryModel(...)` | Generates model fromJson, toJson, equality, copyWith |
| `@Field(...)` | Renames/sets default/converts a model property |
| `@StateModel()` | Generates a sealed state with when/maybeWhen |
| `@Repository(url:)` | Generates a network repository implementation |
| `@Get/@Post/@Put/@Patch/@Delete` | HTTP verb + path on a repository method |
| `@Path('name')` / `@Query('name')` | URL placeholder / query-parameter binding |
| `@Body()` | Serialises the parameter as the request body |
| `@Header(item:)` | Adds a static header to the request |
| `@Subscribe(channel:)` | Stream-based realtime subscription |
| `@Authenticated()` | Routes through the session-aware network adapter |
| `@StateManager()` / `@StateManager(state: X)` | State manager (easy / StateModel mode) |
| `@Event(debounce:, throttle:)` | State-emitting method (auto loading/error) |
| `@StateView(Manager)` | Binds a widget to a state manager |
| `@UseCase(...)` | DI registration for a use-case class |
| `@InjectableInit()` | Marks the DI init function |
| `@Injectable()` / `@Singleton()` / `@LazySingleton()` | Manual DI registration |
| `@Inject('name')` / `@Named('name')` | Named dependency on a constructor param |
| `@RouterConfig()` | Triggers the router code generation |
| `@Screen(path:, name:, access:)` | Registers a screen route, with ACL |
| `@PathParam('name')` / `@QueryParam('name')` | Route parameter extraction |
| `@FormSchema()` | Generates a form state + validation |
| `@Required/@Email/@MinLength/…` | Validators for form fields |
| `@SessionConfig(...)` | Declarative session configuration |
