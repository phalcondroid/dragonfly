# State Management

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

[← Back to README.md](../../README.md)
