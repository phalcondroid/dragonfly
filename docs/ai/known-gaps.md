# Known gaps and constraints

Every item here was **verified against the source**. Read this before
trusting `README.md` (rewritten 2026-08-05) or reporting something as a new bug.

---

## 1. Dead annotations (exported, never consumed)

These are declared in `dragonfly_annotations` and exported, but **no generator reads
them**. Applying them has no effect.

| Annotation | Notes |
| ---------- | ----- |
| `@SessionConfig(...)` | Session config is passed to `DragonflySessionManager.init()` at runtime instead |
| `@PathParam(...)` / `@QueryParam(...)` | Route parameters are consumed by the generated router (implemented), but the annotation itself is read from constructor params, not from fields — field-only usage is dead |
| `@Singleton(...)` — `signalsReady`, `dependsOn`, `dispose` params | The visitor creates the `DependencyConfig` but the config generator ignores these fields for non-lazy-singleton types |

---

## 2. `README.md` documents an API that does not exist (was §1)

**Resolved 2026-08-05.** `README.md` was rewritten to match the v2 framework.
Previous gaps — wrong `@Path`/`@Query` signatures, documented-as-implemented i18n/fpdart,
stale `Feature`/`@StateAction` examples — are removed.

---

## 3. Repository parameters — RESOLVED 2026-08-05

`@Path`, `@Query`, `@Body` and `@Header` are fully wired in the repository generator.
`@Subscribe` parameters pass a real params map. `@Authenticated` resolves the
session-aware adapter. The `DragonflyNetworkHttpAdapter` was refactored with a rich
`requestObject`/`requestList` API (separate `query`, `body` and `headers` arguments) and
hooks (`beforeRequest`, `buildHeaders`, `afterResponse`) so `AuthenticatedNetworkAdapter`
extends it without duplicating 250 lines.

---

## 4. Form validation — RESOLVED 2026-08-05

All three causes are fixed:
- **Missing imports** — auth form sources now import `package:dragonfly/dragonfly.dart`.
- **Naming** — `LoginForm` generates `LoginFormState` (classes already ending in `Form`
  get `State` appended rather than `FormState`).
- **Flutter collision** — `FormFieldState` renamed to `DragonflyFormFieldState`.
- **Form integration** — the generated form state now carries `updateFieldValue`,
  `touchField` and `validateAllFields` methods (self-sufficient, no mixin needed).
  The old `FormControllerMixin` targetting `StateManager<S>` was removed.
- `example/` analyzes clean: **0 errors** across the entire project.

---

## 5. State management — RESOLVED 2026-08-05

The entire v1 stack (`StateManager<S>`, `Feature`, `@StateAction`, `@EventModel`,
`framework/bloc/`, `framework/feature/`) was deleted and replaced with the v2 design:
`@StateManager` plain class, `@Event` returning values, `@StateView` with the `$Manager`
flattened mixin, `DragonflyController`/`DragonflyStateBuilder` runtime.

Rate limiting (`debounce`/`throttle`) survives through `DragonflyController.schedule`.
`@Computed`, `@SideEffect`, `@StateSlot`, `@InitialState` are deleted.

One remaining open design item: the per-state manager per-file output is still the
default; the generated `.state_manager.dart` and `.view.dart` files are `PartBuilder`
outputs. A component-level barrel (`injector.dragonfly.dart`) provides a single-import
convenience but true code consolidation (all generated code in one physical file per
component) requires a builder pass that collects cross-file imports — tracked as a future
item.

---

## 6. Two routers — RESOLVED 2026-08-05

The dead `DragonflyRouter` runtime singleton was deleted. The generated `$AppRouterConfig`
mixin is the sole router. Per-route redirect overrides (`redirectOnDenied` /
`redirectOnUnauthenticated`) are passed in both the static and dynamic ACL branches.
`@PathParam` and `@QueryParam` extract values from the matched route / query string in
the generated route builder.

---

## 7. Silent DI registration — RESOLVED 2026-08-05

- Duplicate registrations now **throw** `DragonflyException` (get_it semantics).
  Add `allowReassignment = true` to override.
- `allReady()`, `allReadySync()` and `isReady()` are implemented: they await / check
  completion of all non-lazy async singletons.
- `DragonflyContainer.reset()` clears all scopes for test teardown.

---

## 8. Toolchain — capped by the Flutter SDK

`analyzer` cannot go above 8.x **from a Flutter app**:

- The Flutter SDK pins `meta 1.18.0`.
- `analyzer >=13.1.0` requires `meta ^1.18.3`.
- `dart_style >=3.1.12` and `build >=4.0.8` both require `analyzer >=13.1.0`.

Current resolved versions: `analyzer 8.4.1`, `source_gen 4.2.4`, `build 4.0.7`,
`dart_style 3.1.3`, `code_builder 4.11.1`, `build_runner 2.15.1`.

Revisit when the Flutter SDK ships `meta >=1.18.3`.

---

## 9. Generator lint hygiene — RESOLVED 2026-08-05

- `_mapEquals` / `_setEquals` helpers (unused) removed from model generator.
- `@override` added to generated `toJson`, `toMap` and `copyWith` methods.
- Leading-underscore locals (`_log`, `_stopwatch`, `_toJsonT`) renamed.
- `getMethodType` uses exact `TypeChecker` matching instead of `toString().contains`.
- `castResultByType`: the copy-pasted `isDartCoreDouble` → `isDartCoreBool` fix.
- `DragonflyConfig.instanceConfigs` no longer force-unwraps `connectTimeout!`.
- All four misspelled identifiers are renamed: `repositoriy/` → `repository/`,
  `MedatadaExtractor` → `MetadataExtractor`, `inyectar.dart` → `inject.dart`,
  `HttpAnnotations.unknow` / `HttpMethods.unknow` → `unknown`. The old
  `Documented don't rename drive-by` rule in `CLAUDE.md` is obsolete — the
  rename was deliberate.

---

## 10. DI annotations — RESOLVED 2026-08-05

`@Injectable`, `@Singleton` and `@LazySingleton` are now scanned by the DI visitor
alongside `@UseCase`, `@Repository` and `@StateManager`. They register the annotated
class as a factory / eager singleton / lazy singleton respectively, with `as`, `env`,
`scope`, `order` and `instanceName` support.

---

## 11. Dead-annotation removal — RESOLVED 2026-08-05

`@Where`, `@JsonKey` and `@JsonIgnore` were deleted (never read by any generator).

---

## Verification commands

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
dart analyze 2>&1 | grep "error -" | wc -l   # expect 0
```

Full suite:
```bash
cd dragonfly_annotations && flutter analyze && dart test
cd dragonfly && flutter analyze && flutter test
cd dragonfly_builder && flutter analyze && dart test
cd example && dart analyze
```
