# Known gaps, drift, and broken subsystems

Every item here was **verified against the source** on 2026-07-27, not inferred from
documentation. Read this before trusting `README.md` or before reporting something as a
new bug.

Each entry states the claim, the reality, and where to look.

---

## 1. `README.md` documents an API that does not exist

`README.md` is aspirational in several places. It is not a reliable specification.

### 1.1 HTTP parameter annotations have the wrong signature

README shows:

```dart
@Get(path: '/character/{id}')
Future<Character> getCharacter(@Path('id') int id);

@Get(path: '/character')
Future<ServiceResponse<Character>> getCharacters(@Query('name') String name);
```

`@Path('id')` and `@Query('name')` **do not compile**. The actual declarations take a
single *named* parameter called `value`:

```dart
// dragonfly_annotations/lib/annotations/network/path.dart
class Path  { final String value; const Path({this.value = ""}); }
// dragonfly_annotations/lib/annotations/network/query.dart
class Query { final String value; const Query({this.value = ""}); }
```

So the only valid forms are `@Path()` / `@Path(value: 'id')` and `@Query()` /
`@Query(value: 'name')`. `example/` uses the bare `@Path()` / `@Query()` form.

### 1.2 Feature names that do not exist anywhere in the source

The project description and README mention these as implemented. They are not:

| Claim                          | Reality                                                        |
| ------------------------------ | -------------------------------------------------------------- |
| i18n / localization            | No match for `i18n`, `intl`, or `Localization` in any package   |
| `fpdart`                       | Not a dependency. `Either` is hand-written in `dragonfly/lib/framework/functional/either.dart` |
| Hive integration               | `HiveSessionStorage` takes a `dynamic _box` and duck-types it; the package never imports Hive. The consuming app owns the dependency |
| `uuid`                         | Was declared with zero usages                                    |

**Resolved 2026-07-27:** `hive`, `hive_flutter`, and `uuid` were removed from
`dragonfly/pubspec.yaml`. They were declared but never imported, so removal required no
code change. `HiveSessionStorage` still works by duck-typing — an app that wants it
depends on Hive itself and passes a `Box`.

### 1.3 Documented DI annotations that do not exist

README's DI table lists `@Singleton()` and `@LazySingleton()` as usable registration
annotations. They exist in `injectable_annotations.dart`, but `InjectableVisitor` only
checks four type checkers — `InjectableUseCase`, `Repository`, `DragonflyBloc`, and
`DragonflyStateManager`. A class annotated `@Singleton()` is **never registered**.

See `dragonfly_builder/lib/builder/visitor/injectable_visitor.dart:21-24`.

---

## 2. The repository layer ignores all request parameters

**This is the most consequential gap in the framework.**

`RepositoryGenerator` never reads `@Path`, `@Query`, `@Body`, or `@Header`. Look at the
generated call it emits — from `example/`, a real committed output:

```dart
// character_repository.repository.dart
final Map<String, Object?> response =
    await network.callForObject(HttpMethods.get, 'character', null, null);
```

The `params` and `options` arguments are **hardcoded to `null`**, and the path is the
literal `@Repository(url:)` value concatenated with `@Get(path:)`. Method parameters are
used for exactly one thing: the logging map.

Concretely, today:

- Path parameters are not substituted. `'/users/{id}'` is sent literally.
- Query parameters are never appended to the URL.
- Request bodies are never sent. Every `@Post`/`@Put`/`@Patch` sends an empty body.
- Headers from `@Get(headers:)` are parsed by `RepositoryVisitor` into `HeaderHelper`
  output and then dropped.

**Note:** this applies to HTTP methods only. `@Subscribe` (realtime) methods are fully
wired — see section 10.

The runtime side is *ready* for this — `DragonflyNetworkHttpAdapter._buildUri` handles
query params and `_encodeBody` handles bodies. Only the generator is missing.

Source: `dragonfly_builder/lib/builder/generators/repository_generator.dart:111` builds
the body string with `$methodKind($httpMethod, '$repoUrl${method.path}', null, null)`.

### 2.1 `ParameterHelper` is the blocker

`dragonfly_builder/lib/builder/visitor/parameter_helper.dart` is 20 lines and has two
defects:

```dart
params.add(ParamsType(
    name: paramElement.displayName,
    paramDataType: "${paramElement.type}",
    value: paramElement.metadata.first.toString().split(" ").first,  // (a)
    type: ParamsAnnotations.path,                                    // (b)
    valueType: ValueType.simple));
```

(a) `metadata.first` **threw** on any parameter without an annotation. The exception was
then swallowed by `RepositoryVisitor.visitMethodElement`'s catch, so the whole method
disappeared from the generated repository.
**Fixed 2026-07-27** — unannotated parameters are now tolerated.

(b) `type:` was hardcoded to `ParamsAnnotations.path` for every parameter.
**Partly fixed** — `_classify` now distinguishes `@Query` from `@Path`. `ParamsAnnotations`
still has no `body`/`header` members, so those remain unclassified.

The remaining work is in `RepositoryGenerator.buildHttpMethod`, which still emits
`null, null` regardless of what the visitor collected.

### 2.2 Dead annotations

`@Body`, `@Header`, and `@Authenticated` are declared in `dragonfly_annotations` and
exported, but **no generator references them**. `grep -rn "Authenticated\|Body\|Header"
dragonfly_builder/lib/` returns nothing. Applying them has no effect whatsoever.

---

## 3. The form-validation subsystem does not compile

`example/`'s `auth` component produces **270 analyzer errors** after a clean
`build_runner build`. The `characters` component is clean. Three independent causes:

### 3.1 Generated part files reference types the source file never imports

`login_form.dart` imports only `package:dragonfly_annotations/dragonfly_annotations.dart`.
Its generated part `login_form.form.dart` references `FormFieldState`, `Validator`,
`Validators`, `CrossFieldValidator`, and `FormController` — all from `package:dragonfly`.

A part file cannot declare imports, so every one of those is an undefined name. Any form
schema source file must also `import 'package:dragonfly/dragonfly.dart';`. Neither the
generator nor the docs say so.

### 3.2 The generated state class name does not match what anything expects

`FormSchemaGenerator` emits `<ClassName>FormState` — for `class LoginForm` that is
**`LoginFormFormState`** (note the doubled `Form`).

But `README.md` says the generated class is `LoginFormState`, and the hand-written
`example/lib/components/auth/presentation/states/login_state.dart` also refers to
`LoginFormState`. That type does not exist, so `LoginState` fails to compile, which
cascades into `login_screen.dart` and `login_state_manager.dart`.

Either the generator should stop appending `FormState` to a name already ending in
`Form`, or every consumer needs updating. Not yet decided.

### 3.3 `FormFieldState` collides with Flutter

`dragonfly/lib/framework/form/form_field_state.dart` defines `FormFieldState<T>` and
`dragonfly.dart` exports it. Flutter's `package:flutter/material.dart` **also** exports
`FormFieldState<T>`. Any file importing both gets an ambiguous-import error. Since form
screens necessarily import Material, this is unavoidable without a rename or an
`export ... hide` clause.

---

## 4. `@StateAction` debounce/throttle — RESOLVED; `@Computed` still discarded

**Partly resolved 2026-07-27.** `debounce` and `throttle` now work.

`StateManager` gained `scheduleAction(key, body, {debounce, throttle})`, backed by
`ActionScheduler` (`dragonfly/lib/framework/state/action_scheduler.dart`), and
`DragonflyStateManagerGenerator` now emits an `actions` façade for every `@StateAction`
that declares a policy:

```dart
// generated
class CharacterFeatureActions {
  const CharacterFeatureActions(this._manager);
  final CharacterFeature _manager;

  /// Runs [CharacterFeature.searchByName], debounced by 300ms.
  bool searchByName(String name) => _manager.scheduleAction(
        'searchByName',
        () => _manager.searchByName(name),
        debounce: const Duration(microseconds: 300000),
      );
}
```

`feature.actions.searchByName(q)` is rate-limited; `feature.searchByName(q)` still runs
immediately. A façade method cannot reuse the action's own name, because the class
declaring the method always wins over a mixin — hence the separate object.

Pending calls are cancelled in `StateManager.dispose()`, so a debounced action cannot fire
against a closed controller.

### Still discarded

- **`@Computed()` generates nothing.** The getter works only because you wrote it by hand.
- **`@StateAction()` with no policy is still decorative** — plain methods called directly.
- **`@SideEffect()` and `@StateSlot()`** have zero references in `dragonfly_builder`.

---

## 4b. Original finding (kept for context)

`DragonflyStateManagerGenerator` does real work to read these annotations:

- `_extractIntents` (line 111) walks every `@StateAction` method and builds an
  `_IntentInfo` carrying its name, params, return type, `shouldLog`, and decoded
  `debounce` / `throttle` `Duration`s.
- `_extractComputedProperties` (line 167) collects every `@Computed` getter.

Both lists are passed into `_generateMixin`. And `_generateMixin` **ignores them**. Its
entire body is:

```dart
buffer.writeln('mixin _\$${className}Mixin on StateManager<$stateType> {');
buffer.writeln('  @override');
buffer.writeln('  bool get loggingEnabled => $logging;');
buffer.writeln('}');
```

Confirmed by the committed output for `CharacterFeature`, which has five `@StateAction`
methods and whose generated mixin is exactly three lines long.

Therefore, today:

- **`@StateAction(debounce: …)` and `@StateAction(throttle: …)` do nothing.** README
  documents debounced search as a working feature. It is not.
- **`@Computed()` generates nothing.** The getter works only because you wrote it by hand.
- **`@StateAction()` itself is decorative** — actions are plain methods called directly on
  the state manager. Removing the annotation changes no generated output.
- `@InitialState()` is used only as a *fallback* for inferring the state type when the
  `StateManager<S>` supertype cannot be read (`_extractStateType`, line 99).
- `@SideEffect()` and `@StateSlot()` have **zero** references in `dragonfly_builder`.

What the generator *does* produce is worth knowing, since it is the framework's main
ergonomic win: a `<Name>Provider` widget, one builder widget per sealed state variant
(`CharacterLoaded`, `CharacterError`, …), and a `BuildContext` extension. Those come from
the **state type's variants**, not from the action annotations.

This is the natural place to start when reimplementing view state management.

---

## 5. Two parallel router implementations, one of them dead

- `dragonfly/lib/framework/navigation/router.dart` — a runtime singleton
  `DragonflyRouter` holding a `Map<String, WidgetBuilder>`, with fade-only transitions
  and **no ACL support**.
- `RouterGenerator` — emits a `$AppRouterConfig` mixin with its own `onGenerateRoute`
  that *does* perform `session.checkAccess(...)`, plus `routeConfigs`, `namedRoutes`,
  and transitions.

`example/lib/components/characters/config/app_config.dart` calls
`DragonflyRouter.instance.configure(...)`, but `main.dart` wires `MaterialApp` to the
**generated** mixin's `onGenerateRoute`. The `DragonflyRouter` singleton is therefore
populated and never read.

Also note the generated router declares `redirectOnDenied` / `redirectOnUnauthenticated`
parameters on `_RouteAccessConfig` that are never passed a value (`unused_element_parameter`
warnings), so per-route redirect overrides in `@DragonflyScreen` do not reach the ACL
check.

---

## 6. Silent DI registration failures

`DragonflyContainer._register` (`dragonfly/lib/framework/di/dragonfly_container.dart:192`):

```dart
if (!allowReassignment && _currentScope.containsKey(key)) {
  return;                    // no throw, no log
}
```

Registering the same type+name twice is a **silent no-op**. The second registration is
discarded and the code that expected it gets the first instance. `get_it` throws here.

Related: `allReady()`, `allReadySync()`, and `isReady()` are stubs that return
immediately regardless of whether async singletons have completed. Code that awaits
`allReady()` before touching an async dependency is not actually protected.

---

## 7. `UseCase` enforces nothing

```dart
abstract interface class UseCase<Params, Error, Response> {
  // No enforced call signature - implement your own
}
```

The interface is empty by design, so the type arguments are documentation only. The
example demonstrates the consequence:

```dart
class GetUserListUseCase
    implements UseCase<Map<String, dynamic>, Error, ServiceResponse<Character>> {
  Future<Either<Error, ServiceResponse<Character>>> call(
      String name, List<String> params) async { … }   // Params says Map, call takes two args
}
```

This compiles. `UseCaseWithParams` and `UseCaseNoParams` do enforce a `call` signature,
but nothing in the framework or docs steers users toward them.

---

## 8. Toolchain — RESOLVED, but capped by the Flutter SDK

**Resolved 2026-07-27.** The builder was migrated from `analyzer 6.4.1` (language version
3.4) to the current element model.

Current resolved versions: `analyzer 8.4.1`, `source_gen 4.2.4`, `build 4.0.7`,
`dart_style 3.1.3`, `code_builder 4.11.1`, `build_runner 2.15.1`.

`dragonfly_annotations` and `dragonfly_builder` were converted to **pure Dart packages**
(no `flutter: sdk: flutter`), since neither uses a Flutter API. Do not add it back — the
Flutter SDK pin is what constrains the analyzer.

### The remaining cap

`analyzer` cannot currently go above 8.x **from a Flutter app**:

- The Flutter SDK pins `meta 1.18.0`.
- `analyzer >=13.1.0` requires `meta ^1.18.3`.
- `dart_style >=3.1.12` and `build >=4.0.8` both require `analyzer >=13.1.0`.

So `analyzer: ^14.1.0` resolves fine in `dragonfly_builder` standalone, but makes
`example/` — and every consuming Flutter app — fail version solving. `build` is therefore
pinned `>=4.0.0 <4.0.8` and `dart_style` to `^3.1.0`. Revisit when the Flutter SDK ships
`meta >=1.18.3`.

Builds still log a **minor** skew warning (analyzer supports 3.11, SDK is 3.12). That is
expected and harmless — down from a 3.4-vs-3.12 gap.

### What the migration changed, for reference

| analyzer 6 | analyzer 8 |
| ---------- | ---------- |
| `package:analyzer/dart/element/visitor.dart` | `.../visitor2.dart` |
| `SimpleElementVisitor<T>` | `SimpleElementVisitor2<T>` |
| `ParameterElement` | `FormalParameterElement` |
| `element.parameters` | `element.formalParameters` |
| `element.accessors` (+ `isGetter` filter) | `element.getters` |
| `element.librarySource.uri` | `element.library.uri` |
| `library.topLevelElements` | `library.classes` |
| `element.metadata` (a `List`) | `element.metadata.annotations` |
| `element.name` is `String` | `element.name` is `String?` |
| `getDisplayString(withNullability: …)` | `getDisplayString()` |
| `TypeChecker.fromRuntime(X)` (source_gen 1) | `TypeChecker.typeNamed(X, inPackage: …)` (source_gen 4) |
| `DartFormatter()` (dart_style 2) | `DartFormatter(languageVersion: …)` (dart_style 3) |

`TypeChecker.typeNamed` matches on the **bare type name**, so every call site passes
`inPackage: 'dragonfly_annotations'`. Without it, generic names like `Field`, `Path`,
`Query`, and `Get` would match same-named types from other packages. Keep that argument
on any new checker.

Generated output changed only in `dart_style` 3 formatting (trailing-comma style); no
semantic differences. `example/` error count was 270 before and after.

---

## 9. Smaller issues

| Issue | Location |
| ----- | -------- |
| `MedatadaExtractor.getMethodType` identifies verbs by `annotation.toString().contains("@Get")` — an annotation named `@GetSomething` would false-match | `helper/metadata_extractor.dart` |
| `castResultByType` tests `isDartCoreDouble` twice; the second branch was meant to be `isDartCoreBool`, so bool annotation fields return `null` | `helper/metadata_extractor.dart` |
| `StateManager.subscribeEither` operates on `Stream<dynamic>` and calls `.isRight`/`.fold` untyped — no compile-time safety | `feature/state_manager.dart` |
| `DragonflyConfig.instanceConfigs` force-unwraps `options.connectTimeout!` | `config/dragonfly_config.dart` |
| Directory named `repositoriy/`, class `MedatadaExtractor`, file `inyectar.dart`, enum value `HttpAnnotations.unknow` — all misspelled, all load-bearing | various |
| Generated `.state.dart` emits unused `_mapEquals` / `_setEquals` helpers | `state_model_generator.dart` |
| Generated models omit `@override` on `toJson`/`toMap`/`copyWith`, producing `annotate_overrides` lint noise in every consuming project | `model_method_builder.dart` |
| Generated code uses leading-underscore locals (`_log`, `_stopwatch`, `_toJsonT`), tripping `no_leading_underscores_for_local_identifiers` in consumers | `repository_generator.dart`, factory model builders |

---

## Verification commands

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
dart analyze 2>&1 | grep -cE "^\s*error"          # expect 270 today
dart analyze 2>&1 | grep -E "^\s*error" | sed 's/.*- lib/lib/' | cut -d: -f1 | sort | uniq -c
```

If that error count drops, update this file.

---

## 10. Realtime / sockets — ADDED 2026-07-27

New subsystem, fully wired end to end. Not a gap; recorded here so the state of the
repository layer is described in one place.

**Runtime**

| Type | File |
| ---- | ---- |
| `DragonflyRealtimeAdapter` (interface) | `network/adapter/dragonfly_realtime_adapter.dart` |
| `DragonflyWebSocketAdapter` | `network/adapter/dragonfly_web_socket_adapter.dart` |
| `DragonflySocketConnection` / `WebSocketConnection` | same file |
| `DragonflyRealtimeConfig` | `network/config/dragonfly_realtime_config.dart` |
| `DragonflyRealtimeInstanceConfig` | `config/dragonfly_config.dart` |

The adapter talks to `DragonflySocketConnection`, not to `WebSocketChannel` directly, so
it can be faked in tests and later backed by SSE or socket.io without changes.

**Annotation** — `@Subscribe(channel:, connection:)` on a `Stream`-returning repository
method; `channel` defaults to the method name. `@Repository(realtimeConnection:)` selects
the transport.

**Generator** — `RepositoryGenerator.buildSubscriptionMethod` emits a method that resolves
a `DragonflyRealtimeAdapter` by connection name and maps each payload through
`fromJson`. `Stream<T>` uses `subscribeToObject`, `Stream<List<T>>` uses `subscribeToList`.

Behaviour worth knowing:

- **The socket opens lazily**, on first `listen`, not at app start. Set
  `connectEagerly: true` to change that.
- **Reconnects use exponential backoff** capped by `maxReconnectDelay`, and subscribe
  frames are replayed on reconnect. A per-binding `subscribed` flag prevents the replay in
  `connect()` and the send in `onListen` from double-subscribing.
- **Malformed JSON frames are logged and skipped**, not surfaced as stream errors — one bad
  frame does not end a subscription. Deserialization failures in the *generated* mapper do
  propagate, since those indicate a model/schema mismatch.
- **Servers without an envelope** are supported by setting `channelField: null`; every
  message then reaches every subscriber on that connection.

Tests: `dragonfly/test/network/web_socket_adapter_test.dart` (15 cases, driven by an
in-memory fake socket).

Unlike the HTTP path, `@Subscribe` methods **do** pass their parameters through — though
the generated code currently sends an empty params map; wiring the values is the same
outstanding work as section 2.
