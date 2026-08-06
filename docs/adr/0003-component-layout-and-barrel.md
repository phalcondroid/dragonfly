# ADR 0003 — Component layout convention and per-component barrel

**Date:** 2026-08-05
**Status:** Accepted
**Deciders:** Framework design session

## Context

The framework prescribes a `lib/components/<name>/` layout with four layers
(config, data, domain, presentation) and eight subdirectories. Every annotated
source file carries a `part` directive for its generated output, producing up to
8 generated files per component; each must be imported individually.

The design session asked for "one file per component" — a single import that
brings all generated code for a component. The preference was directory-convention
discovery (no marker file) with per-file opt-out.

## Decision

**Keep per-file PartBuilder outputs as the default** (proven Dart convention,
chicken-and-egg problem solved by PartBuilder's tolerance of missing part files)
and add an **optional per-component barrel** generated next to the injector file.

### Barrel (component_generator builder)

- Scoped to `config/injector.dart` anchor files (filtered in the builder's `build()`)
- Emits `injector.dragonfly.dart` — a `LibraryBuilder` output re-exporting every
  source file whose generated part lives in the component
- Uses `package:` URIs so the barrel works regardless of its own location
- Screens are excluded (their generated view mixins may collide when several
  screens bind the same `@StateManager`)
- Opt-out: consumers override `component_generator` in their `build.yaml`

### Why not true consolidation?

True code consolidation (all generated classes in one physical file per component)
requires:
1. Every generator to emit standalone output (not part-of), with its own import
   collection for payload/model types
2. A new aggregator builder that collects cross-file type references
3. The generator to handle type visibility across files (Dart imports aren't
   transitive)

The import-collection problem alone made this a separate-project-level effort.
The barrel provides the single-import convenience with zero fragility.

### Directory convention

Components are discovered by path: `lib/components/<name>/config/injector.dart`
is the anchor. The `component_generator` derives the component root from path
segments (no `@Component` marker annotation needed). This matches the question #4
(Session Jul 27-28) answered by the sketch: "consolidated by default with per-file
opt-out."

## Consequences

- 9th builder added to `build.yaml`/`builder.dart`
- `auto_apply: dependents` means the barrel is generated for all consumers
  following the convention
- A consumer migrating to the convention just needs to create the `injector.dart`
  anchor file

## References

- `dragonfly_builder/lib/builder/generators/component_generator.dart`
- `build.yaml` component_generator block
