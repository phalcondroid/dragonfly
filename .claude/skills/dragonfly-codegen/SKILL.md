---
name: dragonfly-codegen
description: Add or modify a Dragonfly code generator — a new annotation in dragonfly_annotations plus its source_gen builder in dragonfly_builder. Use when the task involves creating an annotation, writing or changing a Generator or Visitor, editing build.yaml or lib/builder.dart, or changing what any *.model.dart / *.state.dart / *.repository.dart / *.state_manager.dart / *.form.dart / *.config.dart / *.router.dart file contains.
---

# Adding or changing a Dragonfly generator

Read `docs/ai/codegen-pipeline.md` first if you have not — it explains PartBuilder vs
LibraryBuilder and the whole-package scanner pattern. This skill is the procedure.

## Before you start

Confirm the baseline builds, so you can tell your breakage from pre-existing breakage:

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
dart analyze 2>&1 | grep -cE "^\s*error"
```

Record that number. The `characters` component should be clean; the `auth` component is
known-broken and contributes most of the count (`docs/ai/known-gaps.md` #3).

---

## Procedure

### 1. Declare the annotation

`dragonfly_annotations/lib/annotations/<area>/<name>.dart`:

```dart
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

@immutable
@Target({TargetKind.classType})
class MyAnnotation {
  final String someOption;
  final bool enabled;

  const MyAnnotation({this.someOption = '', this.enabled = true});
}
```

Rules: const constructor, no behaviour, no dependency on `package:dragonfly`. Defaults on
every field — `ConstantReader.peek` returns `null` for anything the user omits, and a
default keeps the generator simple.

Export it from `dragonfly_annotations/lib/dragonfly_annotations.dart` with an explicit
`show`. **Unexported means unusable**, even though it compiles.

### 2. Write the visitor (only if you need structure)

`dragonfly_builder/lib/builder/visitor/my_visitor.dart`:

```dart
class MyVisitor extends SimpleElementVisitor<void> {
  final List<MyThing> things = [];

  @override
  void visitMethodElement(MethodElement element) {
    things.add(MyThing(name: element.displayName, /* … */));
  }
}
```

Accumulate into public fields; the generator reads them after `element.visitChildren(v)`.
Remember `visitChildren` sees direct children only — use `element.allSupertypes` for
inherited members.

Prefer `TypeChecker.fromRuntime(MyAnnotation)` over string matching. Do **not** copy
`MetadataExtractor.getMethodType`'s `toString().contains("@Get")` approach.

### 3. Write the generator

`dragonfly_builder/lib/builder/generators/my_generator.dart`:

```dart
class MyGenerator extends GeneratorForAnnotation<MyAnnotation> {
  final _formatter = DartFormatter();

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@MyAnnotation can only be applied to classes.',
        element: element,
      );
    }

    final enabled = annotation.peek('enabled')?.boolValue ?? true;

    final visitor = MyVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();
    // … emit code …
    return _formatter.format(buffer.toString());
  }
}
```

**Do not wrap the body in `try { … } catch (e) { print(e); return ""; }`.** That pattern
is all over this codebase and it is why generator bugs are invisible — an empty part file
is emitted and `build_runner` still reports success. Either let the exception propagate,
or use `InvalidGenerationSourceError` (which build_runner surfaces properly), or
`log.severe(...)` from `package:build`.

Emit with `code_builder` for structure and raw strings for statement bodies. Always finish
with `DartFormatter().format(...)` — if it throws, your output is not valid Dart.

### 4. Register in `lib/builder.dart`

```dart
/// Builder for @MyAnnotation annotated classes.
/// Output extension: `.mything.dart`
Builder myGenerator(BuilderOptions options) => PartBuilder(
      [MyGenerator()],
      '.mything.dart',      // the FINAL extension
      options: options,
    );
```

Use `LibraryBuilder(MyGenerator(), generatedExtension: '.mything.dart')` instead if the
output is a standalone file rather than a `part of`.

### 5. Register in `build.yaml`

```yaml
  my_generator:
    import: "package:dragonfly_builder/builder.dart"
    builder_factories: ["myGenerator"]
    build_extensions: { ".dart": [".mything.part"] }   # .part for PartBuilder!
    auto_apply: dependents
    build_to: source
    applies_builders: ["source_gen|combining_builder"]
```

For a `LibraryBuilder`, declare `[".mything.dart"]` and **omit** `applies_builders`. Copy
the `router_generator` entry as the model, not `injectable_config_builder` (whose
`applies_builders` line is inert).

Missing either step 4 or step 5 means the builder never runs, with no error.

### 6. Exercise it from `example/`

Generators have no unit tests in this repo — `example/` is the test suite. Add a minimal
usage in `example/lib/components/`, then:

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
```

### 7. Verify for real

```bash
cat lib/path/to/your_file.mything.dart   # is it non-empty and plausible?
dart analyze 2>&1 | grep -cE "^\s*error" # compare against your recorded baseline
```

Both checks are required. An empty output file with a green build means your generator
threw and something swallowed it.

---

## If the generated part references runtime types

A part file cannot import anything. If you emit `DragonflyContainer`, `FormFieldState`,
`DragonflyController`, or any other `package:dragonfly` type, the **user's source file**
must import `package:dragonfly/dragonfly.dart` — and Flutter's `material.dart` too if you
emit widgets.

You cannot add that import for them. So: document it in the annotation's dartdoc, and
consider throwing `InvalidGenerationSourceError` when the required import is absent,
which you can detect via `element.library.importedLibraries`.

This is exactly what broke the form subsystem (`docs/ai/known-gaps.md` #3.1).

---

## If your generator needs whole-package knowledge

Follow `InjectableConfigGenerator` / `RouterGenerator` / `FactoryModelRegistry`:

```dart
final glob = Glob('lib/**.dart');
await for (final assetId in buildStep.findAssets(glob)) {
  try {
    final library = await buildStep.resolver.libraryFor(assetId);
    for (final e in library.topLevelElements) { /* … */ }
  } catch (_) {
    continue;
  }
}
```

Be aware of the cost: this re-resolves the entire package on every build and defeats
incrementality. And the `catch { continue; }` silently drops libraries that fail to
resolve — if you write a scanner, log the skip rather than swallowing it:

```dart
} catch (e) {
  log.warning('Skipped $assetId while scanning: $e');
  continue;
}
```

---

## Checklist

- [ ] Annotation is const, `@immutable`, has defaults, lives in `dragonfly_annotations`
- [ ] Annotation exported with `show` from `dragonfly_annotations.dart`
- [ ] `dragonfly_builder` does **not** import `package:dragonfly`
- [ ] Generator does not swallow exceptions into an empty string
- [ ] Output passed through `DartFormatter().format(...)`
- [ ] Registered in `lib/builder.dart`
- [ ] Registered in `build.yaml` with `.part` (PartBuilder) or `.dart` (LibraryBuilder)
- [ ] Exercised from `example/`
- [ ] Generated file inspected and non-empty
- [ ] `dart analyze` error count is no worse than baseline
- [ ] New runtime types the generator references are exported from `dragonfly.dart`
- [ ] Emits canonical names (`StateManager`, never `Feature`)
