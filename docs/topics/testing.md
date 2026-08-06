# Testing

Dragonfly provides a minimal TDD API for testing state managers. It is
designed to be simpler than `bloc_test` — fewer callbacks, no hidden
parameters, explicit lifecycle control, and optimized for AI agent code
generation.

---

## Table of Contents

- [Quick start](#quick-start)
- [Step-by-step tutorial](#step-by-step-tutorial)
  - [1. Testing a simple controller](#1-testing-a-simple-controller)
  - [2. Testing async events (loading → result)](#2-testing-async-events-loading--result)
  - [3. Testing failures (loading → error)](#3-testing-failures-loading--error)
  - [4. Testing generated controllers with mocks](#4-testing-generated-controllers-with-mocks)
  - [5. Testing debounced and throttled events](#5-testing-debounced-and-throttled-events)
  - [6. Testing StateModel-mode managers](#6-testing-statemodel-mode-managers)
  - [7. Testing easy-mode managers](#7-testing-easy-mode-managers)
  - [8. Manual lifecycle with ControllerStates](#8-manual-lifecycle-with-controllerstates)
  - [9. Standalone pump for legacy tests](#9-standalone-pump-for-legacy-tests)
- [API reference](#api-reference)
- [Comparison with bloc_test](#comparison-with-bloc_test)
- [AI agent integration](#ai-agent-integration)

---

## Quick start

The TDD API lives in `package:dragonfly/dragonfly.dart`. Three concepts:

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';
```

| API | When to use |
|-----|------------|
| `controllerTest()` | Every state manager test — the default choice |
| `ControllerStates` | When you need to interleave multiple actions and assertions |
| `pump()` | Standalone microtask flush for hand-rolled listeners |

---

## Step-by-step tutorial

### 1. Testing a simple controller

Start with a minimal controller that just increments a counter:

```dart
class CounterController extends DragonflyController<int> {
  CounterController() : super(0);

  Future<void> increment() async => emit(state + 1);
  void reset() => emit(0);
}
```

The test follows a 3-step lifecycle: **create → act → expect**.

```dart
void main() {
  test('emits incremented value', () async {
    final controller = CounterController();

    await controllerTest<int>(
      () => controller,
      act: (_) => controller.increment(),
      expect: (r) {
        expect(r.states, [1]);
        expect(r.controller.state, 1);
      },
    );
  });
}
```

**What happens under the hood:**
1. `create()` returns the controller
2. A stream listener collects every `emit()` call into `r.states`
3. `act()` calls `controller.increment()`, which calls `emit(1)` synchronously
4. Two microtask pumps flush the stream delivery
5. `expect(r)` receives the collected states and the controller itself
6. The subscription and controller are disposed automatically

**Key detail:** The initial state (`0`) is NOT in `r.states` — only explicit
`emit()` calls appear. Check `r.controller.state` for the sync state at any
point.

### 2. Testing async events (loading → result)

Generated controllers automatically emit `loading` before every `@Event`
method and the return value as the result variant:

```dart
class _AsyncController extends DragonflyController<_LoadState> {
  _AsyncController() : super(_LoadLoading());

  Future<void> fetch(String id) async {
    emit(_LoadLoading());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    emit(_LoadResult('data-$id'));
  }
}
```

```dart
test('emits loading then result on fetch', () async {
  final controller = _AsyncController();

  await controllerTest<_LoadState>(
    () => controller,
    act: (_) => controller.fetch('42'),
    expect: (r) {
      expect(r.states[0], isA<_LoadLoading>());
      expect(r.states[1], isA<_LoadResult>());
      expect((r.states[1] as _LoadResult).value, 'data-42');
    },
  );
});
```

The double-pump in `controllerTest` handles the microtask delivery: first
pump for the synchronous `emit(loading)`, second for the async completion
→ `emit(result)`.

### 3. Testing failures (loading → error)

Same pattern — errors are just state variants:

```dart
test('emits loading then error on failure', () async {
  final controller = _AsyncController();

  await controllerTest<_LoadState>(
    () => controller,
    act: (_) => controller.fail(),
    expect: (r) {
      expect(r.states[0], isA<_LoadLoading>());
      expect(r.states[1], isA<_LoadError>());
      expect((r.states[1] as _LoadError).message, 'not found');
    },
  );
});
```

In generated controllers, thrown exceptions are caught and emitted as the
`error` variant automatically — no try/catch needed in tests.

### 4. Testing generated controllers with mocks

Generated `$XController` classes take the annotated delegate as a
constructor parameter. Mock the delegate to isolate the controller:

```dart
// The annotated delegate — injected dependencies go here
class CharacterStateManager {
  CharacterStateManager(this._useCase);
  final GetUserListUseCase _useCase;

  @Event()
  Future<CharacterState> fetchCharacters() async { ... }
}

// The generated controller — wraps the delegate
// class $CharacterStateManagerController extends DragonflyController<CharacterState> {
//   $CharacterStateManagerController(this._delegate);
//   // auto-loading, auto-error, event dispatch
// }
```

**With mocks (write by hand or use mockito/mocktail):**

```dart
class MockCharacterStateManager implements CharacterStateManager {
  final List<Character> mockCharacters;
  final String? mockError;

  MockCharacterStateManager({this.mockCharacters = const [], this.mockError});

  Future<CharacterState> fetchCharacters() async {
    if (mockError != null) {
      throw Exception(mockError);
    }
    return CharacterState.loaded(character: mockCharacters.first);
  }
}
```

**The test:**

```dart
test('emits loading then loaded on successful fetch', () async {
  final delegate = MockCharacterStateManager(
    mockCharacters: [Character(id: 1, name: 'Rick')],
  );
  final controller = $CharacterStateManagerController(delegate);

  await controllerTest<CharacterState>(
    () => controller,
    act: (_) => controller.fetchCharacters(),
    expect: (r) {
      expect(r.states[0], isA<CharacterStateLoading>());
      expect(r.states[1], isA<CharacterStateLoaded>());
      expect(r.controller.state, isA<CharacterStateLoaded>());
    },
  );
});
```

**For dependency-injected use cases**, mock the repository:

```dart
class MockCharacterRepository implements CharacterRepository {
  @override
  Future<ServiceResponse<Character>> getAll(String name) async =>
      ServiceResponse(results: [Character(id: 1, name: name)]);
}

test('use case → state manager integration', () async {
  final useCase = GetUserListUseCase(MockCharacterRepository());
  final delegate = CharacterStateManager(useCase);
  final controller = $CharacterStateManagerController(delegate);

  await controllerTest<CharacterState>(
    () => controller,
    act: (_) => controller.fetchCharacters(),
    expect: (r) {
      expect(r.states[1], isA<CharacterStateLoaded>());
    },
  );
});
```

### 5. Testing debounced and throttled events

`@Event(debounce:)` and `@Event(throttle:)` create pending dispatches in the
`ActionScheduler`. Use `r.flush('key')` to fire them instantly:

```dart
test('debounces search to a single call', () async {
  final controller = _SearchController();

  await controllerTest<SearchState>(
    () => controller,
    act: (_) {
      // Type 'R', then 'Ri', then 'Ric' — only the last should fire
      controller.search('R');
      controller.search('Ri');
      controller.search('Ric');
    },
    expect: (r) async {
      // Nothing fired yet — all three calls collapsed by debounce
      expect(r.states, isEmpty);

      // Fire the pending dispatch now
      await r.flush('search');
      expect(r.states.length, 2);               // loading + result
      expect(r.states[1], isA<SearchLoaded>());
    },
  );
});
```

The `flush` key matches the event method name in generated controllers.
For throttled events, `flush` resets the throttle gate and runs the
pending call immediately.

### 6. Testing StateModel-mode managers

`@StateManager(state: CharacterState)` mode — the user provides the state
class, the controller auto-emits loading/error:

```dart
@StateModel()
sealed class CharacterState with _$CharacterState {
  const CharacterState._();
  const factory CharacterState.initial() = CharacterStateInitial;
  const factory CharacterState.loading() = CharacterStateLoading;
  const factory CharacterState.loaded({required Character character}) = CharacterStateLoaded;
  const factory CharacterState.error({required String message}) = CharacterStateError;
}
```

```dart
test('auto-emits loading before the event runs', () async {
  final delegate = MockCharacterStateManager(mockCharacters: [rick]);
  final controller = $CharacterStateManagerController(delegate);

  await controllerTest<CharacterState>(
    () => controller,
    act: (_) => controller.fetchCharacters(),
    expect: (r) {
      // Loading is auto-emitted by the generated controller
      expect(r.states[0], isA<CharacterStateLoading>());
      expect(r.states[1], isA<CharacterStateLoaded>());
      // Sync state is the last emitted
      expect(r.controller.state, isA<CharacterStateLoaded>());
    },
  );
});

test('auto-emits error when the event throws', () async {
  final delegate = MockCharacterStateManager(mockError: 'Network failure');
  final controller = $CharacterStateManagerController(delegate);

  await controllerTest<CharacterState>(
    () => controller,
    act: (_) => controller.fetchCharacters(),
    expect: (r) {
      expect(r.states[0], isA<CharacterStateLoading>());
      expect(r.states[1], isA<CharacterStateError>());
      expect((r.states[1] as CharacterStateError).message, 'Network failure');
    },
  );
});
```

### 7. Testing easy-mode managers

`@StateManager()` without a state type — the sealed state is generated
from `@Event` return types. The test pattern is identical:

```dart
// Generated state variants: initial, loading, search({value: ...}), clear, error
test('emits search result on successful query', () async {
  final delegate = MockSearchStateManager(mockResults: [rick, morty]);
  final controller = $CharacterSearchStateManagerController(delegate);

  await controllerTest<CharacterSearchStateManagerState>(
    () => controller,
    act: (_) => controller.search('Rick'),
    expect: (r) {
      expect(r.states[0], isA<CharacterSearchStateManagerStateLoading>());
      expect(r.states[1], isA<CharacterSearchStateManagerStateSearch>());
      expect(
        (r.states[1] as CharacterSearchStateManagerStateSearch).value,
        [rick, morty],
      );
    },
  );
});
```

### 8. Manual lifecycle with ControllerStates

When you need to interleave multiple actions and assertions within one
test — a wizard flow, a multi-step form, a polling sequence — use
`ControllerStates` for explicit control:

```dart
test('tracks state across a multi-step wizard', () async {
  final controller = WizardController();
  final cs = ControllerStates<WizardState>(controller);

  // Step 1 — enter name
  controller.enterName('Rick');
  await cs.pump();
  expect(cs.events[0], isA<WizardNameEntered>());
  expect(controller.state, isA<WizardNameEntered>());

  // Step 2 — select plan
  controller.selectPlan('premium');
  await cs.pump();
  expect(cs.events[1], isA<WizardPlanSelected>());

  // Step 3 — confirm
  await controller.confirm();
  await cs.pump();
  await cs.pump();                       // double-pump for async
  expect(cs.events.last, isA<WizardConfirmed>());

  cs.dispose();
  controller.dispose();
});
```

### 9. Standalone pump for legacy tests

For tests that manage their own stream subscriptions, `pump()` is a
standalone microtask flush:

```dart
test('flushes stream after a direct emit call', () async {
  final controller = CounterController();
  final states = <int>[];
  final sub = controller.stream.listen(states.add);

  controller.reset();                    // emits 0
  await pump();
  expect(states, [0]);

  await sub.cancel();
  controller.dispose();
});
```

---

## API reference

### `controllerTest<S>(create, {act, expect})`

| Parameter | Type | Purpose |
|-----------|------|---------|
| `S` | State type | Inferred from `create` return type |
| `create` | `DragonflyController<S> Function()` | Builds the controller under test |
| `act` | `Future<void> Function(DragonflyController<S>)` | Triggers an event on the controller |
| `expect` | `FutureOr<void> Function(ControllerResult<S>)` | Assert on collected states and controller |

**Lifecycle:**
1. `create()` → builds controller
2. Subscribes to `controller.stream` → collects emissions into `r.states`
3. `act(controller)` → triggers the event
4. Pumps microtasks twice → sync emit delivery + async completion
5. `expect(r)` → assertions on `r.states` and `r.controller.state`
6. **Always** cancels subscription and calls `controller.dispose()` in `finally`

### `ControllerResult<S>`

| Member | Type | Purpose |
|--------|------|---------|
| `controller` | `DragonflyController<S>` | Access sync state, dispose, etc. |
| `states` | `List<S>` | Every emitted state, in order (initial state excluded) |
| `flush(key)` | `Future<void>` | Fast-forward a debounced/throttled dispatch + pump |
| `pump()` | `Future<void>` | Pump the microtask queue once |

### `ControllerStates<S>`

| Member | Type | Purpose |
|--------|------|---------|
| `controller` | `DragonflyController<S>` | The observed controller |
| `events` | `List<S>` | Every state that arrived since creation |
| `pump()` | `Future<void>` | Pump the microtask queue |
| `flush(key)` | `Future<void>` | Fast-forward a debounced dispatch + pump |
| `dispose()` | `void` | Cancel stream subscription (does NOT dispose controller) |

### `pump()`

```dart
Future<void> pump();
```

Flushes the microtask queue so pending stream deliveries arrive. Equivalent
to `await Future<void>.delayed(Duration.zero)`.

---

## Comparison with bloc_test

| Aspect | `bloc_test` | `controllerTest` |
|--------|------------|-----------------|
| Parameters | 10+ (build, act, expect, skip, wait, errors, verify, setUp, tearDown, ...) | 3 (create, act, expect) |
| Type parameters | Required: `blocTest<Bloc, State>(...)` | Inferred from `create` return type |
| State collection | Opaque, async, gated by `wait` duration | Explicit `r.states` list |
| Initial state | Emitted to stream → requires `skip: 1` | Not in stream → no `skip` needed |
| Error channel | Separate `errors` stream assertion | Errors are state variants (`State.error(...)`) |
| Debounce test | Real timer (`wait: Duration(seconds: 1)`) | `r.flush('key')` — instantaneous |
| Mocking | Code-generated `whenListen()` helper | Plain Dart mocks (hand-written or mockito) |
| Lines for a simple test | ~12 | ~8 |
| Closure factories | `build`, `act`, `expect`, `verify` all closures | `create` factory + direct method call in `act` |

### Why it's simpler

1. **No closure factories** — `create` is a factory; `act` receives the
   controller directly so you call `.fetchCharacters()` rather than wrapping
   it in a closure.
2. **No hidden parameters** — the 3-step lifecycle is explicit and visible
   in every test body.
3. **Synchronous emit** — `DragonflyController.emit()` is sync, so states
   arrive predictably without `wait` durations.
4. **Errors are states** — no separate error channel. A failed event emits
   `CharacterState.error(message: '...')`.
5. **No `skip`** — the initial state is never emitted to the stream.
6. **AI-friendly** — 3 parameters, predictable lifecycle, dead simple to
   generate from an annotation or a natural-language prompt.

---

## AI agent integration

The TDD API is designed for AI code generation. The pattern is deterministic
enough that an agent can generate a complete test from three pieces of
information:

1. The controller type and state type
2. The event method name and its return type
3. Whether the event is async, debounced, or synchronous

### Generation template

```
Given:
  Controller:     $CharacterStateManagerController
  State:          CharacterState (sealed: initial, loading, loaded, error)
  Event:          fetchCharacters() → Future<CharacterState>

Generate:
  test('emits loading then loaded on successful fetch', () async {
    final delegate = MockCharacterStateManager(mockResult: testValue);
    final controller = $CharacterStateManagerController(delegate);

    await controllerTest<CharacterState>(
      () => controller,
      act: (_) => controller.fetchCharacters(),
      expect: (r) {
        expect(r.states[0], isA<CharacterStateLoading>());
        expect(r.states[1], isA<CharacterStateLoaded>());
        expect(r.controller.state, isA<CharacterStateLoaded>());
      },
    );
  });
```

### Deterministic assertions

The TDD API eliminates ambiguity that trips up AI generators:

| Ambiguity | Solution |
|-----------|----------|
| "What does `skip` do?" | No `skip` — initial state is never in the stream |
| "Do I need `wait`?" | No `wait` — double-pump handles all async completions |
| "Which states should I expect?" | Always: `[loading, result]` for success, `[loading, error]` for failure |
| "How do I test debounce?" | `r.flush('eventName')` — no real timers |
| "Do I dispose manually?" | No — `controllerTest` auto-disposes in `finally` |

### Mock pattern

For AI-generated mocks, prefer hand-written stub classes over code-gen
mocking libraries. A stub is a plain Dart class that implements the
delegate interface and returns canned values:

```dart
// AI generates this stub from the delegate interface
class StubCharacterStateManager implements CharacterStateManager {
  final Object? result;
  StubCharacterStateManager({this.result});

  Future<CharacterState> fetchCharacters() async {
    if (result is Exception) throw result as Exception;
    return result as CharacterState;
  }
}
```

The stub pattern is:
- **Deterministic** — no `when/thenReturn` chains, no `.called(1)` verification
- **Fewer dependencies** — no mockito/mocktail import needed
- **Easier to read** — the stub body IS the documentation of expected behavior

[← Back to README.md](../../README.md)
