# Dragonfly — Agent Guide (framework development)

This file is for an agent working **on the Dragonfly framework itself**: the runtime,
the annotations, and the code generators. It is not a tutorial for building apps with
Dragonfly — for that, see `dragonfly/ai/` (the bundle shipped to consumer projects).

Everything here was verified against the source. Where the source and `README.md`
disagree, **the source wins** and the disagreement is recorded in
`docs/ai/known-gaps.md`. Read that file before you trust `README.md`.

---

## Repository layout

```
.
├── dragonfly/              # Runtime library (Flutter package). No codegen here.
├── dragonfly_annotations/  # Annotation classes only. Pure Dart + meta. No logic.
├── dragonfly_builder/      # source_gen builders. Depends on annotations, not runtime.
├── example/                # Flutter app used as the integration test for codegen.
└── docs/ai/                # Deep reference for agents (see index below).
```

Dependency direction is strict and must stay that way:

```
dragonfly_builder ──▶ dragonfly_annotations ◀── dragonfly
                                                    ▲
example ────────────────────────────────────────────┘
```

`dragonfly_builder` must **never** import `package:dragonfly`. Generators emit code
that *references* runtime types by name; they do not link against them. If you find
yourself wanting that import, you want a string literal instead.

---

## Commands

All commands run from `example/` unless stated otherwise — that is the only package
that actually exercises the builders.

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate
dart run build_runner watch  --delete-conflicting-outputs  # iterate on a generator
dart analyze                                               # verify generated output compiles
```

To check the packages themselves:

```bash
cd dragonfly            && flutter analyze
cd dragonfly_annotations && flutter analyze
cd dragonfly_builder     && flutter analyze
```

**A green `build_runner` run does not mean the generators worked.** See the trap below.

---

## The single most important thing to know

Nearly every generator wraps its whole body in `try { … } catch (e) { print(…); return ""; }`.

`RepositoryGenerator.generateForAnnotatedElement`
(`dragonfly_builder/lib/builder/generators/repository_generator.dart:56`) is the
clearest example, and `RepositoryVisitor.visitMethodElement`
(`dragonfly_builder/lib/builder/visitor/repository_visitor.dart:60`) does the same
per-method.

Consequences you must internalise:

1. A generator crash produces an **empty or partial part file**, and `build_runner`
   still prints `Succeeded`.
2. The real error only appears as a `print` line in the build log, buried among
   `[INFO]` lines. Grep for `error on` / `====>>>` when output looks wrong.
3. **`dart analyze` is the real pass/fail signal**, not the build_runner exit code.
   Always analyze after generating.

When you touch a generator, verify with `build_runner build` **followed by**
`dart analyze`, and compare the generated file's contents — not just its existence.

---

## Naming: what is canonical

State management is the **v2 API** (the old `StateManager<S>`/`Feature` stack was
deleted in a clean break — do not try to "restore" it):

| Canonical (emit this)                          | Removed predecessor (gone, not deprecated)      |
| ---------------------------------------------- | ----------------------------------------------- |
| `@StateManager()` on a plain class             | `@DragonflyStateManager()` + `StateManager<S>`  |
| `@StateManager(state: XState)` (StateModel mode) | `@DragonflyFeature()`, `@DragonflyView()`     |
| `@Event()` method → state variant              | `@StateAction()` + hand-written `emit(...)`     |
| `@StateView(Manager)` on a widget              | `@DragonflyBlocView`, provider wrapping         |
| `$XController extends DragonflyController<S>`  | `StateManagerProvider` / `StateManagerBuilder`  |
| view mixin `$X` (`when`/`build<Event>`/`buildFor`) | `context.stateManager<T>()`, `StateScope`   |

A `@StateManager` class has **no base class and no mixin**: the generator emits the
controller (auto `loading`/`error` dispatching, DI lazy singleton) and, in easy mode,
the sealed state class itself. `@Event` methods return values, never call `emit`.

Renamed annotations with **live** deprecated aliases (keep working, never emit):
`@UseCase` (was `@InjectableUseCase`), `@InjectableInit` (was `@DragonflyInjectableInit`),
`@Screen` (was `@DragonflyScreen`), `@SessionConfig` (was `@DragonflySessionConfig`),
`@RouterConfig` (was `@DragonflyRouterConfig`).

Also deleted in the clean break: the whole `framework/bloc/` directory,
`StateScope`/`StateView`/`StateSelector`, `@EventModel`, `@InitialState`, `@SideEffect`,
`@Computed`, `@StateSlot`, `@DragonflyStateBuilder`, and the `UseCase` contract
interfaces (the name now belongs to the annotation).

---

## Documentation index

Read these on demand rather than all at once:

| File                                    | When to read it                                              |
| --------------------------------------- | ------------------------------------------------------------ |
| `docs/ai/architecture.md`               | Runtime layer internals: DI, network, state, session, router |
| `docs/ai/codegen-pipeline.md`           | How the 10 builders wire together; part vs library builders  |
| `docs/ai/annotation-matrix.md`          | Every annotation → its generator → its output. Lookup table. |
| `docs/ai/known-gaps.md`                 | Verified drift, dead parameters, and broken subsystems       |
| `.claude/skills/dragonfly-codegen/`     | Step-by-step: add a new annotation + generator               |
| `.claude/skills/dragonfly-build-debug/` | Step-by-step: diagnose a generator that produced wrong code  |
| `.claude/skills/dragonfly-runtime/`     | Step-by-step: change runtime library code safely             |

---

## Hard rules

### Never hand-edit generated files

These are build outputs. Edit the **generator**, then rebuild:

```
*.model.dart      *.state.dart     *.view.dart
*.repository.dart *.form.dart      *.state_manager.dart
*.config.dart     *.router.dart    *.dragonfly.dart
```

They all carry `// GENERATED CODE - DO NOT MODIFY BY HAND`. If you need different
output, the fix is always in `dragonfly_builder/lib/builder/`.

Note these files **are currently committed to git** (there is no `.gitignore` entry
for them). That is deliberate for now — it lets you read real generator output as a
reference — but it also means a stale generated file can mislead you. Regenerate
before drawing conclusions from one.

### Keep the three-package boundary

- New annotation → `dragonfly_annotations`. Const constructor, `@immutable`,
  `@Target(...)` where meaningful, no behaviour.
- New generator → `dragonfly_builder`. Register in **both** `lib/builder.dart` and
  `build.yaml` or it silently never runs.
- New runtime type → `dragonfly`, and export it from `lib/dragonfly.dart` with an
  explicit `show` clause. The barrel file uses `show` everywhere; an unexported type
  is invisible to consumers even though the file compiles.

### Don't "fix" the known typos casually

The four historically-misspelled identifiers (`repositoriy/`, `MedatadaExtractor`,
`inyectar.dart`, `HttpAnnotations.unknow`) have all been corrected as a deliberate
rename in August 2026. If you encounter legacy references, update them. Do not
reintroduce the old spellings.

---

## Environment

- Dart SDK on this machine: **3.12.2**. All three packages declare `sdk: ^3.8.0`.
- `dragonfly_annotations` and `dragonfly_builder` are **pure Dart packages**. They
  declare no Flutter dependency, which is what allows the builder to track a modern
  analyzer. Do not add `flutter: sdk: flutter` back to either one.
- Toolchain: `analyzer 8.4.1`, `source_gen 4.2.4`, `build 4.0.7`, `dart_style 3.1.3`,
  `code_builder 4.11.1`.
- **The analyzer is capped at 8.x, and not by choice.** The Flutter SDK pins
  `meta 1.18.0`, while `analyzer >=13.1.0` requires `meta ^1.18.3`; `dart_style >=3.1.12`
  and `build >=4.0.8` both require `analyzer >=13.1.0`. Raising any of them resolves fine
  in `dragonfly_builder` alone but makes `example/` — and every consuming Flutter app —
  fail version solving. Revisit when the Flutter SDK ships `meta >=1.18.3`.
- `example/`: the `characters` component builds and analyzes clean (**0 errors**);
  the `auth` / form-validation component is **broken-by-default** (224 errors, all
  confined to `components/auth`). Characters demonstrates both state-manager modes:
  `CharacterStateManager` (StateModel mode) and `CharacterSearchStateManager`
  (easy mode). Treat `characters` as the reference implementation.
- Naming trap: `@StateView` was almost `@View` — Flutter exports a `View` widget via
  `material`, so the annotation had to be renamed. Any file importing
  `flutter/material.dart` can only use `StateView`.
