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

1. **Never hand-edit generated files.** `*.model.dart`, `*.state.dart`,
   `*.repository.dart`, `*.form.dart`, `*.state_manager.dart`, `*.view.dart`,
   `*.config.dart`, `*.router.dart`, `*.dragonfly.dart`. Fix the generator instead.
2. **A new generator must be registered twice** — in `dragonfly_builder/lib/builder.dart`
   *and* in `dragonfly_builder/build.yaml`. Miss either and it silently never runs.
3. **Export new runtime types** from `dragonfly/lib/dragonfly.dart`. That barrel uses
   explicit `show` clauses, so an unexported type is invisible to consumers.
4. **State management is v2 only.** `@StateManager` on a plain class (no base class),
   `@Event` methods returning values (never `emit`), `@StateView(Manager)` widgets with
   the `$Manager` mixin. The old `StateManager<S>`/`Feature` stack, `framework/bloc/`,
   `@StateAction`, `@EventModel` and friends were deleted in a clean break — do not
   reintroduce them. Renamed annotations (`@UseCase`, `@InjectableInit`, `@Screen`,
   `@SessionConfig`, `@RouterConfig`) keep live deprecated aliases; never emit the old
   names in new code.
5. **The historical typos were fixed in August 2026** — `MetadataExtractor`,
   `repository/`, `inject.dart`, `unknown`. If you encounter the old spellings
   in legacy references, update them. Do not reintroduce the old spellings.
6. **Routing lives on the config class.** `@RouterConfig()` goes on the `DragonflyConfig` subclass — never in a separate file. One config object delivers DI, network, session, and routing.

7. **Trust the source over `README.md`.** The README documents an API that in several
   places does not exist. `docs/ai/known-gaps.md` lists every verified discrepancy.
8. **Every change updates the docs.** After any framework change, run the
   checklist in `.claude/skills/dragonfly-docs-sync/SKILL.md`. Documentation is
   not optional — an outdated doc is a bug. The change isn't done until all
   affected docs match the new reality and the full verification gate passes.

## Current state

- `example/`'s `characters` component builds and analyzes clean (**0 errors**) — the
  reference implementation, demonstrating both state-manager modes
  (`CharacterStateManager` StateModel mode, `CharacterSearchStateManager` easy mode).
- `example/`'s `auth` component (form validation) does **not** compile (224 errors,
  confined to `components/auth`). Known broken.
- `analyzer` is capped at 8.x because the Flutter SDK pins `meta 1.18.0` (see
  `CLAUDE.md` "Environment").

Details: `docs/ai/known-gaps.md`.
