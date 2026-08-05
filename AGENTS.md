# AGENTS.md

Instructions for AI coding agents working on the **Dragonfly framework** (this repo).
Tool-agnostic mirror of `CLAUDE.md`; that file and `docs/ai/` hold the full detail.

## What this repo is

A Flutter framework that replaces the usual stack (freezed, injectable, get_it, retrofit,
bloc, fpdart) with one annotation set and one code generator suite, so that app authors
write only use cases and UI. Three published packages plus an example app:

| Path                     | Role                                                        |
| ------------------------ | ----------------------------------------------------------- |
| `dragonfly/`             | Runtime: DI container, network, state management, session   |
| `dragonfly_annotations/` | Annotation classes only — no logic                          |
| `dragonfly_builder/`     | `source_gen` builders that read those annotations           |
| `example/`               | Flutter app; the de-facto integration test for the builders |

`dragonfly_builder` must never import `package:dragonfly`. It emits references to
runtime types as strings.

## Build and verify

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

**`build_runner` reporting success proves nothing.** Generators swallow their own
exceptions (`catch (e) { print(...); return ""; }`) and emit empty output on failure
while the build still reports `Succeeded`. `dart analyze` is the real signal. Always
run it after generating, and read the generated file to confirm it has real content.

## Rules

1. **Never hand-edit generated files.** `*.model.dart`, `*.state.dart`, `*.event.dart`,
   `*.repository.dart`, `*.form.dart`, `*.state_manager.dart`, `*.blocview.dart`,
   `*.bloc.dart`, `*.config.dart`, `*.router.dart`. Fix the generator instead.
2. **A new generator must be registered twice** — in `dragonfly_builder/lib/builder.dart`
   *and* in `dragonfly_builder/build.yaml`. Miss either and it silently never runs.
3. **Export new runtime types** from `dragonfly/lib/dragonfly.dart`. That barrel uses
   explicit `show` clauses, so an unexported type is invisible to consumers.
4. **`StateManager` is canonical; `Feature` is deprecated.** Never emit `Feature`,
   `@DragonflyFeature`, `@DragonflyView`, `@ViewAction`, `context.feature<T>()`, or
   `FeatureBuilder` in new code. The aliases must keep working, but are not for new use.
5. **Do not rename the known typos** as a side effect of other work:
   `MedatadaExtractor`, the `repositoriy/` directory, `inyectar.dart`,
   `HttpAnnotations.unknow`. They are load-bearing identifiers.
6. **Trust the source over `README.md`.** The README documents an API that in several
   places does not exist. `docs/ai/known-gaps.md` lists every verified discrepancy.

## Current state

- `example/`'s `characters` component builds and analyzes clean — use it as the
  reference implementation.
- `example/`'s `auth` component (form validation) does **not** compile. Known broken.
- `analyzer` is pinned to `^6.0.0` (language version 3.4) against a 3.12 SDK, so every
  build logs a version-skew warning.

Details for all three: `docs/ai/known-gaps.md`.
