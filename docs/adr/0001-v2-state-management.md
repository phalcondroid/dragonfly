# ADR 0001 — State management v2 (clean break from v1)

**Date:** 2026-08-05
**Status:** Accepted
**Deciders:** Framework design session (Jul 27-28, 2026)

## Context

The v1 state-management stack (`StateManager<S>`, `Feature`, `@StateAction`,
`@DragonflyFeature`, `StateManagerProvider`, `StateManagerBuilder`, `StateScope`,
`StateView`, `bloc/`) accumulated layers of partial fixes:

- `@StateAction(debounce:)`/`throttle:` were parsed then discarded (gap #4)
- `@Computed()` parsed then discarded
- `@SideEffect()`/`@StateSlot()` never read
- The generated provider/builder widgets depended on `InheritedWidget` propagation
- The BLoC-generator path was a parallel legacy subsystem with no migration path

## Decision

A **clean break** — delete the entire v1 stack and replace it with:

1. **Plain-class state managers**: `@StateManager` on a class with no base/mixin.
   `@Event` methods return values (never call `emit`). Auto `loading`/`error`
   dispatching is generated.

2. **Flattened view mixin**: `@StateView(Manager)` generates a `$Manager` mixin
   that places `when(...)`, typed `build<Variant>`, `buildFor(...)`, and event
   dispatchers directly on the widget. No provider, no `context.stateManager<T>()`.

3. **DI-resolved controllers**: Generated `$XController extends DragonflyController<S>`
   is registered as a lazy singleton. The view mixin resolves it without a
   `BuildContext` — this is what makes the flattened API possible without provider
   wrapping.

4. **Two modes**: Easy mode (state class generated from `@Event` methods) and
   StateModel mode (binds to a `@StateModel` sealed class).

## Consequences

**Deleted**: `framework/feature/`, `framework/bloc/`, `framework/state/state_scope.dart`,
`framework/state/state_view.dart`, `@StateAction`, `@EventModel`, `@DragonflyStateManager`,
`@Computed`, `@SideEffect`, `@StateSlot`, `@InitialState`, `@DragonflyStateBuilder`,
`@DragonflyBloc`, `@DragonflyBlocView`, `class Bloc`.

**Kept**: `ActionScheduler` (debounce/throttle backing), `@StateModel` (unchanged).

**Renamed**: `@DragonflyInjectableInit` → `@InjectableInit`, `@DragonflyScreen` → `@Screen`,
`@DragonflySessionConfig` → `@SessionConfig`, `@DragonflyRouterConfig` → `@RouterConfig`,
`@InjectableUseCase` → `@UseCase`. Live `@Deprecated` typedef aliases preserve back-compat.

**Design decisions answered by the session (Jul 27-28)**:
- Event semantics: auto loading + error, explicit success
- View mixin: flatten onto the widget (no accessor object)
- Old API: clean break, delete it
- The `build` string-keyed builder renamed to `buildFor` to avoid collision with
  `StatelessWidget.build(BuildContext)`

**Open**: One-file-per-component true consolidation (current per-file PartBuilder
output is the default; a barrel file provides single-import convenience).

## References

- `docs/ai/architecture.md` § "State management runtime (v2)"
- `docs/ai/annotation-matrix.md` § "Deleted in the v2 clean break"
- `dragonfly_annotations/lib/annotations/component/presentation/state_manager.dart`
- `dragonfly_builder/lib/builder/helper/state_manager_descriptor.dart`
