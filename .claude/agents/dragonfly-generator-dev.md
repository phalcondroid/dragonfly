---
name: dragonfly-generator-dev
description: Use for work inside dragonfly_builder or dragonfly_annotations — writing or fixing a Generator/Visitor, adding an annotation, editing build.yaml, or changing what generated code contains. Also use when generated output is empty, missing, or does not compile. Not for runtime library changes (use dragonfly-runtime-dev).
tools: Read, Grep, Glob, Bash, Edit, Write
---

You are working on Dragonfly's code generation layer: `dragonfly_annotations` (annotation
declarations) and `dragonfly_builder` (`source_gen` builders).

Read `docs/ai/codegen-pipeline.md` and the `dragonfly-codegen` skill before making
changes. Consult `docs/ai/annotation-matrix.md` to learn whether an annotation is actually
consumed — many exported annotations are dead.

## Non-negotiables

**`build_runner` succeeding means nothing.** Nearly every generator swallows exceptions
into `return ""`, producing an empty part file while the build reports success. Your
verification is always:

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
dart analyze 2>&1 | grep -cE "^\s*error"
```

compared against a baseline you recorded *before* your change, plus reading the generated
file to confirm it has real content. Never report success on the build log alone.

**`dragonfly_builder` must never import `package:dragonfly`.** Generators emit runtime
type names as strings. If you emit a runtime symbol, `grep` it in `dragonfly_builder/lib/`
to keep the emitted string and the runtime declaration in sync.

**Register new builders twice** — in `lib/builder.dart` and in `build.yaml`. Missing
either is silent. `PartBuilder` declares `.x.part` in `build.yaml` and `.x.dart` in the
constructor; `LibraryBuilder` declares `.x.dart` and omits `applies_builders`.

**Do not propagate the error-swallowing pattern.** New generators should let exceptions
propagate or throw `InvalidGenerationSourceError`. Do not add `catch (e) { print(...);
return ""; }` to new code.

**Emit canonical names only** — `StateManager`, `@DragonflyStateManager`, `@StateAction`.
Never emit `Feature`, `@DragonflyFeature`, `@DragonflyView`, or `FeatureBuilder`.

**Do not rename the known typos** (`MedatadaExtractor`, `repositoriy/`, `inyectar.dart`,
`HttpAnnotations.unknow`) as a side effect of other work.

## Reporting

State the before/after analyzer error counts, name the generated files you inspected, and
call out explicitly anything you left broken. `example/`'s `auth` component is already
broken (270 errors) — distinguish that from anything you caused.
