---
name: dragonfly-runtime
description: Modify the Dragonfly runtime library (package:dragonfly) — the DI container, network adapters, StateManager and its widgets, session/ACL, router, logging, forms, or Either/JSON helpers. Use when changing anything under dragonfly/lib/framework/ or the dragonfly.dart barrel export, especially when generated code depends on the symbol you are touching.
---

# Changing the Dragonfly runtime

`docs/ai/architecture.md` describes what each subsystem does. This skill is about changing
it without breaking the generators that emit references to it.

## The constraint that makes this different from normal refactoring

Generated code refers to runtime types **by name, as strings**. `dragonfly_builder` does
not import `package:dragonfly`, so the compiler cannot catch a mismatch. Renaming a
runtime symbol that a generator emits produces code that fails only at the consumer's
`dart analyze`, long after your change looks fine.

**Before renaming or changing the signature of any public runtime symbol**, check whether
a generator emits it:

```bash
grep -rn "TheSymbolName" dragonfly_builder/lib/
```

A hit means you must update the generator's emitted string in the same change.

### Symbols generators currently emit — treat as a public contract

| Symbol | Emitted by |
| ------ | ---------- |
| `DragonflyContainer.I`, `.get<T>(instanceName:)`, `registerSingleton` / `registerLazySingleton` / `registerFactory` | repository, injectable config, state manager generators |
| `DragonflyLogManager.instance` | repository generator |
| `repositoryStart` / `repositorySuccess` / `repositoryError` | repository generator |
| `DragonflyNetworkHttpAdapter`, `callForObject`, `callForList` | repository generator |
| `HttpMethods.get/post/put/patch/delete` | repository generator |
| `DragonflyController<S>`, `DragonflyStateBuilder<S>`, `DragonflyContainer` | state manager + view generators |
| `DragonflySessionManager.instance`, `checkAccess(...)` | router generator |
| `AccessLevel.*` | router generator |
| `DragonflyFormFieldState`, `Validators`, `Validator`, `CrossFieldValidator`, `FormController` | form schema generator |

Changing any of these means changing a generator string too.

---

## Procedure

### 1. Locate the subsystem

```
dragonfly/lib/framework/
├── di/          DragonflyContainer, scopes, EnvironmentFilter
├── network/     adapters, options, HTTP exceptions
├── feature/     StateManager + provider/builder widgets  (name is historical)
├── session/     session manager, ACL, storage, authenticated adapter
├── navigation/  DragonflyRouter, context extensions
├── form/        FormFieldState, Validators, FormController, validated widgets
├── logging/     log manager, formatter, levels, entries
├── functional/  Either
├── mapper/      JsonDatatypeMapper
├── config/      DragonflyApp, DragonflyConfig, network/storage config
└── contracts/   UseCase, FactoryModelWatcher
```

### 2. Make the change

Match surrounding style: `@protected` on members only subclasses should call,
`@mustCallSuper` on lifecycle methods, dartdoc with a `///` example on public types.

### 3. Export it

```dart
// dragonfly/lib/dragonfly.dart
export 'package:dragonfly/framework/thing/my_thing.dart' show MyThing, MyThingCallback;
```

The barrel uses explicit `show` on **every** export. A public type not listed there is
invisible to consumers and to generated code, even though the package compiles.

Watch for name collisions with Flutter. `DragonflyFormFieldState` already collides with
`package:flutter/material.dart` and breaks every form screen
(`docs/ai/known-gaps.md` #3.3). Before exporting a new name, check it against Material's
exports; prefer a `Dragonfly` prefix for anything generic-sounding.

### 4. Deprecate rather than break

The established pattern, from the v2 annotation renames:

```dart
@Deprecated('Use @UseCase instead')
typedef InjectableUseCase = UseCase;
```

Keep the old name working, mark it, add
`// ignore_for_file: deprecated_member_use_from_same_package` to files that must reference
it. Canonical names are the unprefixed ones (`@UseCase`, `@Screen`, `@StateManager`,
`@Event`, `@StateView`); never introduce new uses of the `Dragonfly`-prefixed aliases.
Exception to this rule: the v2 state stack (`StateManager<S>`, `Feature`, bloc/) was a
documented clean break — deleting an API wholesale is acceptable only as an explicit,
standalone task, never as a side effect.

### 5. Verify against the example

The runtime has essentially no unit tests (`dragonfly/test/dragonfly_test.dart` is a stub).
`example/` is the integration test:

```bash
cd dragonfly && flutter analyze
cd ../example && dart run build_runner build --delete-conflicting-outputs && dart analyze
```

Compare the error count to the baseline in `docs/ai/known-gaps.md`. If you changed a
symbol a generator emits, `git diff` the generated files to confirm they still reference
something real.

---

## Subsystem-specific cautions

**DI container** — `_register` **throws** `DragonflyException` on duplicates (set
`allowReassignment = true` to override). `allReady()`, `allReadySync()` and `isReady()`
are implemented — they await / check completion of async singletons. `DragonflyContainer.reset()`
clears all scopes for test teardown.

**Network** — generated repositories look up the **concrete**
`DragonflyNetworkHttpAdapter`, not the `DragonflyBaseNetworkAdapter` interface. A new
adapter registered under the interface type will not be found. Adding a transport (e.g.
sockets) requires touching the generator, not just the runtime.

**State management (v2)** — `DragonflyController.emit` is `@protected`; keep it that way —
only generated controllers mutate state. `dispose()` must stay idempotent and cancel the
`ActionScheduler` before closing the stream. Controllers are DI **lazy singletons**; that
is what lets the `$Manager` view mixin resolve without a `BuildContext`, so do not
re-register them as factories without redesigning the view mixin too.

**Session** — `checkAccess` is called by generated routers; its return contract is
"redirect path, or `null` to allow". Changing that silently breaks every generated router.

**Logging** — the `repository*` and `view*` methods are a generator-facing API, not
internal helpers. Their named parameters appear verbatim in emitted code.

**Forms** — this subsystem does not currently compile end to end. Read
`docs/ai/known-gaps.md` #3 before changing it, so you fix the real cause rather than a
symptom.

---

## Checklist

- [ ] `grep -rn "Symbol" dragonfly_builder/lib/` run before any rename
- [ ] Generator emitted strings updated in the same change
- [ ] New public types exported from `dragonfly.dart` with `show`
- [ ] New public names checked against `package:flutter/material.dart` for collisions
- [ ] Old names kept as `@Deprecated` typedefs rather than removed
- [ ] `flutter analyze` clean in `dragonfly/`
- [ ] `example/` rebuilt and analyzed; error count no worse than baseline
