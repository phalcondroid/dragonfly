# ADR 0006 — Naming canonicalisation and typo cleanup

**Date:** 2026-08-05
**Status:** Accepted
**Deciders:** Framework design session + gap-fix pass

## Context

Every annotation originally carried a `Dragonfly` prefix (`@DragonflyStateManager`,
`@DragonflyInjectableInit`, `@DragonflyScreen`, ...). The design session
mandated: "refactor every annotation with @Dragonfly, now remove and just set
the name of functionality that it is doing."

Four load-bearing identifiers were historically misspelled:
- Directory `repositoriy/` (correct: `repository/`)
- Class `MedatadaExtractor` (correct: `MetadataExtractor`)
- File `inyectar.dart` (correct: `inject.dart`)
- Enum values `HttpAnnotations.unknow` / `HttpMethods.unknow` (correct: `unknown`)

The v1 `CLAUDE.md` explicitly instructed agents **not** to fix these casually —
but the gap-fix pass was a deliberate, dedicated rename.

## Decision

### Annotation renames (with `@Deprecated` typedef aliases)

| Old | New |
|-----|-----|
| `@DragonflyStateManager` | `@StateManager` (new semantics, see ADR 0001) |
| `@DragonflyInjectableInit` | `@InjectableInit` |
| `@DragonflyScreen` | `@Screen` |
| `@DragonflySessionConfig` | `@SessionConfig` |
| `@DragonflyRouterConfig` | `@RouterConfig` |
| `@InjectableUseCase` | `@UseCase` |

The `Dragonfly`-prefixed aliases remain as `@Deprecated typedef` declarations in
the annotations package so existing source files continue to compile.

### Typo renames (no aliases — the old names are gone)

| Old | New |
|-----|-----|
| `repositoriy/` directory | `repository/` |
| `MedatadaExtractor` class | `MetadataExtractor` |
| `inyectar.dart` file | `inject.dart` |
| `HttpAnnotations.unknow` | `HttpAnnotations.unknown` |
| `HttpMethods.unknow` | `HttpMethods.unknown` |

### Deleted dead annotations (no aliases)

`@Where`, `@JsonKey`, `@JsonIgnore` — never read by any generator, superseded or
useless. Deleted from annotations package and barrel.

`@DragonflyRoute` kept but unexported (internal to `router_config.dart`).

## Consequences

- `CLAUDE.md`/`AGENTS.md` rule #5 changed from "do not rename" to "were corrected;
  do not reintroduce old spellings."
- All imports of `repositoriy/repository.dart` updated to `repository/repository.dart`.
- `ParamsAnnotations` enum value `where` kept (dead value, not a typo — it was a
  valid enum member for a planned feature).

## References

- `dragonfly_annotations/lib/annotations/injectable/injectable_annotations.dart`
- `dragonfly_annotations/lib/annotations/session/session_annotations.dart`
- `dragonfly_annotations/lib/annotations/navigation/router_config.dart`
- `dragonfly_builder/lib/builder/helper/metadata_extractor.dart`
