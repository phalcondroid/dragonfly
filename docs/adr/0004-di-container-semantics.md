# ADR 0004 — DI container: throw on duplicate, implement readiness, add reset

**Date:** 2026-08-05
**Status:** Accepted
**Deciders:** Gap-fix pass (see `docs/ai/known-gaps.md` #6)

## Context

`DragonflyContainer._register` silently returned on a duplicate key, discarding the
second registration without logging or throwing. `allReady()`, `allReadySync()`,
and `isReady()` were no-op stubs that returned immediately regardless of whether
async singletons had completed. The container had no `reset()` method, making test
teardown fragile.

The silent-no-op behaviour was dangerous: code registering a second instance under
the same key believed it was setting up the new instance, but callers received the
**first** instance instead. This class of bug is extremely hard to diagnose.

## Decision

1. **Throw on duplicate** — `_register` throws `DragonflyException` with the type
   and instance name when `allowReassignment` is false (get_it semantics).
   `allowReassignment = true` is the escape hatch for deliberate overriding.

2. **Implement readiness** — `allReady()` awaits every non-lazy async singleton's
   creation future across all scopes. `allReadySync()` checks that every non-lazy
   async singleton has `_instance != null`. `isReady<T>()` awaits or returns
   immediately depending on whether `T` is an async singleton.

3. **Add `reset()`** — Disposes every entry in every scope and returns the
   container to a single empty scope. Primarily for test teardown.

## Consequences

- Existing code that relied on double-registration being harmless will now throw
  at runtime. Internal registration sites (config init, DI visitor) are guarded
  with `isRegistered()` checks, so they are safe. External consumers that
  register manually must add guards.
- `allReady()` blocks until async singletons finish — callers that used the
  old no-op for fast startup may see a real delay. Ensure `allReady()` is called
  after `configureDependencies()`, not before.
- The `component_generator`-produced `.dragonfly.dart` barrel can be re-imported
  safely (it only exports, doesn't register).

## References

- `dragonfly/lib/framework/di/dragonfly_container.dart`
- `docs/ai/known-gaps.md` #7
