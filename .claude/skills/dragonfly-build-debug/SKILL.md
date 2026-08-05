---
name: dragonfly-build-debug
description: Diagnose Dragonfly code generation problems — empty or missing generated files, a dependency absent from injector.config.dart, a route missing from the generated router, analyzer errors in generated output, or build_runner reporting success while the app does not compile. Use whenever generated output is wrong rather than when writing a new generator.
---

# Debugging Dragonfly code generation

## The rule that governs everything

**`build_runner` exiting 0 proves nothing.** Almost every generator in this repo does:

```dart
try { … } catch (e) { print("====>>>>>>>>> error on …"); return ""; }
```

so a crash yields an *empty part file* and a green build. `dart analyze` on `example/` is
the real signal. Never conclude "the build passes" from build_runner alone.

---

## Triage in order

### 1. Reproduce cleanly

```bash
cd example
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs 2>&1 | tee /tmp/df-build.log
dart analyze 2>&1 | tee /tmp/df-analyze.log
```

### 2. Look for swallowed exceptions

They only ever appear as `print` output, interleaved with `[INFO]` lines:

```bash
grep -nE "====>>|error on |Error generating|Failed to format" /tmp/df-build.log
```

Known emitters and what they mean:

| Message | Source | Meaning |
| ------- | ------ | ------- |
| `error on repository generator` | `repository_generator.dart:56` | Whole repository impl is empty |
| `error on methods visitor` | `repository_visitor.dart:60` | **One method** silently missing from the impl |
| `error processing use case/repository/bloc/state manager` | `injectable_visitor.dart` | That dependency missing from `.config.dart` |
| `Error generating state manager code` | `dragonfly_feature_generator.dart` | Emitted as a comment into the part file |
| `Failed to format generated code` | `injectable_config_generator.dart` | Output is syntactically invalid Dart |

### 3. Group the analyzer errors by file

```bash
grep -E "^\s*error" /tmp/df-analyze.log \
  | sed 's/.*- lib/lib/' | cut -d: -f1 | sort | uniq -c | sort -rn
```

Then compare against the known baseline in `docs/ai/known-gaps.md`. Errors confined to
`lib/components/auth/**` are pre-existing and not yours.

### 4. Read the generated file

```bash
wc -l lib/path/to/thing.model.dart
head -40 lib/path/to/thing.model.dart
```

Empty, or containing only the header comment, means the generator threw. A file that is
*missing entirely* means the builder never ran at all — go to the next section.

---

## Symptom → cause

### Generated file does not exist

1. Is the `part 'name.ext.dart';` directive present in the source file? `PartBuilder`
   output requires it.
2. Is the builder registered in **both** `dragonfly_builder/lib/builder.dart` and
   `dragonfly_builder/build.yaml`? Missing either is silent.
3. Does `build.yaml` declare the `.part` extension for a `PartBuilder` (not `.dart`)?
4. Is the annotation actually imported and applied in the source file?

### Generated file is empty or truncated

The generator threw. Find the `print` line (step 2). Then temporarily remove the
`try/catch` in that generator so the real stack trace surfaces, and rerun.

### A method is missing from a generated repository

`RepositoryVisitor.visitMethodElement` catches per method. The usual cause is
`ParameterHelper.parametersResolver` calling `paramElement.metadata.first` on a parameter
that has **no annotation**, which throws `Bad state: No element`. Annotate every parameter,
or fix `ParameterHelper` (`docs/ai/known-gaps.md` #2.1).

### A dependency is missing from `injector.config.dart`

`InjectableConfigGenerator` globs the package and does `catch { continue; }` on any
library it cannot resolve. So:

1. **Fix unrelated compile errors first.** A file that does not compile is skipped
   silently, taking its `@InjectableUseCase` with it.
2. Check the annotation is one of the four `InjectableVisitor` actually looks for:
   `@InjectableUseCase`, `@Repository`, `@DragonflyBloc`, `@DragonflyStateManager`.
   `@Singleton` / `@LazySingleton` / `@Injectable` are **never scanned**.
3. Widgets are deliberately excluded — anything extending `Widget` is skipped.
4. For `@DragonflyStateManager`, the class must genuinely extend `StateManager` or
   `Feature`; `_processDragonflyStateManager` returns early otherwise.
5. `injectable: false` on the annotation opts out.

### A route is missing from the generated router

`RouterGenerator` uses the same glob-and-skip pattern. Same rule: fix other files' compile
errors first. Also confirm `@DragonflyScreen` is on a class, and that the referenced
`provider:` type is an annotated state manager (the first pass indexes those separately).

### Generated code compiles in isolation but not in the app

The part file references a type the **source file** does not import. Part files cannot
import. Add `import 'package:dragonfly/dragonfly.dart';` — and `package:flutter/material.dart`
if the generated code contains widgets — to the annotated source file.

### `DartFormatter` throws

The emitted string is not valid Dart. Print it before formatting:

```dart
final code = buffer.toString();
log.info(code);            // inspect, then
return _formatter.format(code);
```

Common causes: an unbalanced brace in a raw `Code("""…""")` body, or a type name
interpolated as `null`.

### Stale output

`build_to: source` means outputs are real files on disk and are committed. A stale one can
outlive the generator change that produced it:

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
git status --short          # what actually changed?
```

`git diff` on generated files is the fastest way to see a generator change's true effect.

---

## Iterating on a generator

```bash
cd example
dart run build_runner watch --delete-conflicting-outputs
```

`watch` picks up edits to `dragonfly_builder` (it is a path dependency). If it stops
reacting, kill it, `clean`, and restart — the asset graph occasionally goes stale after
`build.yaml` edits. **`build.yaml` changes always require a restart.**

---

## Known noise to ignore

- `Your current analyzer version may not fully support your current SDK version` on every
  build — analyzer is pinned to `^6.0.0` against a 3.12 SDK (`docs/ai/known-gaps.md` #8).
- `annotate_overrides`, `no_leading_underscores_for_local_identifiers`, and
  `unused_element` **info/warning** lints from generated files. Cosmetic generator defects,
  not build failures.
- 270 errors from `lib/components/auth/**`. Known broken subsystem.
