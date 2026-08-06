# The code generation pipeline

How `dragonfly_builder` turns annotations into Dart. Read this before adding or
modifying a generator.

---

## The nine builders

Every builder is declared in **two** places. Both are required.

1. `dragonfly_builder/lib/builder.dart` — a top-level
   `Builder xxx(BuilderOptions options)` factory function.
2. `dragonfly_builder/build.yaml` — a `builders:` entry naming that factory.

| build.yaml key                      | Factory                          | Output ext         | Shape           |
| ----------------------------------- | -------------------------------- | ------------------ | --------------- |
| `repository_generator`              | `repositoryGenerator`            | `.repository.dart` | `PartBuilder`   |
| `factory_model_generator`           | `factoryModelGenerator`          | `.model.dart`      | `PartBuilder`   |
| `state_model_generator`             | `stateModelGenerator`            | `.state.dart`      | `PartBuilder`   |
| `state_manager_generator`           | `stateManagerGenerator`          | `.state_manager.dart` | `PartBuilder` |
| `view_generator`                    | `viewGenerator`                  | `.view.dart`       | `PartBuilder`   |
| `form_schema_generator`             | `formSchemaGenerator`            | `.form.dart`       | `PartBuilder`   |
| `injectable_config_builder`         | `injectableConfigBuilder`        | `.config.dart`     | `LibraryBuilder`|
| `router_generator`                  | `routerBuilder`                  | `.router.dart`     | `LibraryBuilder`|
| `component_generator`               | `componentBuilder`               | `.dragonfly.dart`  | `LibraryBuilder`|

The five `PartBuilder`s use `applies_builders: ["source_gen|combining_builder"]` in
`build.yaml`. The four `LibraryBuilder`s emit standalone files and do not. All nine
use `auto_apply: dependents` and `build_to: source`. (`event_model_generator` and
the two bloc generators were deleted in the v2 state-management clean break.)

The `component_generator` is scoped to `config/injector.dart` anchor files (filtered
in its `build()` method), so exactly one `.dragonfly.dart` barrel is produced per
component directory, re-exporting all generated sources.

`FactoryModelGenerator` also reads `@Aggregate` and `@ValueObject` annotations on the
same class (via element metadata, not TypeChecker) to adjust equality semantics and
add aggregate-root methods. `@DomainEvent` is a marker annotation — no generator
processes it; the runtime `DomainEvent` interface is the contract.

### PartBuilder vs LibraryBuilder — the extension gotcha

For a `PartBuilder`, the extension you pass to the constructor and the extension you
declare in `build.yaml` **are deliberately different**:

```dart
// lib/builder.dart — the FINAL extension
Builder factoryModelGenerator(BuilderOptions options) =>
    PartBuilder([FactoryModelGenerator()], '.model.dart', options: options);
```

```yaml
# build.yaml — the INTERMEDIATE extension
build_extensions: { ".dart": [".model.part"] }
applies_builders: ["source_gen|combining_builder"]
```

`source_gen` writes a `.model.part` fragment, then `combining_builder` merges all
fragments into the final `.model.dart`. This is the same convention `json_serializable`
and `injectable` use. If you declare `.model.dart` in `build.yaml` for a `PartBuilder`,
the build breaks.

A `LibraryBuilder` writes a standalone file and needs no `combining_builder`. Note that
`injectable_config_builder` currently declares `applies_builders: ["source_gen|combining_builder"]`
even though it is a `LibraryBuilder` — that line is inert. `router_generator` correctly
omits it. Copy `router_generator`, not `injectable_config_builder`.

### Consequences for the annotated source file

A `PartBuilder` output is a `part of`. The source file must therefore declare it:

```dart
part 'character.model.dart';
```

and — critically — **the source file must import everything the generated part
references**. A part file cannot have its own imports. This is the root cause of the
broken `auth` component: `login_form.dart` imports only `dragonfly_annotations`, while
the generated `login_form.form.dart` references `FormFieldState`, `Validators`,
`Validator`, `CrossFieldValidator`, and `FormController` from `package:dragonfly`.
See `known-gaps.md`.

When you write a generator that emits a runtime type, you own the problem of telling
users which import to add. There is no mechanism that adds it for them.

---

## The two generator shapes in this codebase

### Shape A — single-element generators

Most generators only look at the annotated element:

```
GeneratorForAnnotation<TheAnnotation>
  └─ generateForAnnotatedElement(element, annotation, buildStep)
       ├─ element.visitChildren(SomeVisitor())     // collect structure
       ├─ map visitor output → models/ or types/   // typed intermediate
       └─ code_builder → DartEmitter → DartFormatter().format(...)
```

Example: `FactoryModelGenerator`, `StateModelGenerator`, `StateManagerGenerator`.

`StateManagerGenerator` and `ViewGenerator` share one analysis pass,
`StateManagerDescriber.describe` (`helper/state_manager_descriptor.dart`): given the
`@StateManager` class it produces the descriptor both generators emit from (modes,
events, variants, auto loading/error flags). Change dispatch semantics in exactly one
place or the controller and the view mixin disagree.

### Shape B — whole-package scanners

Three generators need to see the *entire* package, not just their annotated element.
They glob every library and resolve it:

```dart
final glob = Glob('lib/**.dart');
await for (final assetId in buildStep.findAssets(glob)) {
  try {
    final library = await buildStep.resolver.libraryFor(assetId);
    // ... inspect library.topLevelElements
  } catch (e) {
    continue;   // <-- silently skips unresolvable libraries
  }
}
```

| Scanner                                      | Why it scans                                              |
| -------------------------------------------- | --------------------------------------------------------- |
| `InjectableConfigGenerator`                  | Find every `@UseCase` / `@Repository` / `@StateManager` in the package to build one DI graph (state managers produce two registrations: delegate factory + controller lazy singleton) |
| `RouterGenerator`                            | Find every `@Screen` to map routes and their ACL config |
| `FactoryModelRegistry` (used by `RepositoryGenerator`) | Learn each `@FactoryModel`'s generics and `fromJson` shape so the repository can emit the right `fromJson` call |

Note `ViewGenerator` is **not** a scanner: it resolves the bound `@StateManager` class
directly through the annotation's `Type` argument, which is also how it learns the
manager's mode and variants without globbing.

**The `catch { continue; }` in all three is a real hazard.** A library that fails to
resolve — because *its own* generated part is missing or broken — is skipped without a
word. The symptom is a dependency mysteriously absent from `injector.config.dart`, or a
route missing from the router. If something you annotated does not appear in generated
output, this is the first thing to suspect: fix the *other* file's compile error and
rebuild.

Scanners also make the build order-sensitive and hurt incrementality — each scanner
re-resolves the whole package on every run.

---

## Visitors

Visitors live in `dragonfly_builder/lib/builder/visitor/` and extend
`SimpleElementVisitor<void>` from `package:analyzer`. They accumulate into public
fields; the generator reads those fields afterward.

```dart
class RepositoryVisitor extends SimpleElementVisitor<void> {
  late String className;
  final List<MethodRepositoryType> methods = [];

  @override
  void visitConstructorElement(ConstructorElement element) { … }

  @override
  void visitMethodElement(MethodElement element) { … }
}
```

Driven by `element.visitChildren(visitor)`. Note `visitChildren` only reaches *direct*
children — it does not recurse into supertypes. For inherited members use
`element.allSupertypes` explicitly, as `InjectableVisitor._isFlutterWidget` does.

Existing visitors and what they extract:

| Visitor                 | Extracts                                                       |
| ----------------------- | -------------------------------------------------------------- |
| `RepositoryVisitor`     | Method name, HTTP verb, path, params, return type + generics    |
| `FactoryModelVisitor`   | Model fields with type classification (class/list/map/set)      |
| `InjectableVisitor`     | DI registrations from four different annotations                |
| `SealedClassVisitor`    | Sealed-class variants for state/event models                    |
| `UseCaseVisitor`        | Use-case call signatures                                        |

Helper classes (`ParameterHelper`, `ReturnHelper`, `HeaderHelper`,
`MetadataExtractor` — note the spelling) do the string-level parsing.

**`ReturnHelper` and `MetadataExtractor` parse type *strings*, not type objects.**
`MetadataExtractor.getMethodType` literally does
`item.toString().contains("@Get")`. This is fragile — an annotation named `@GetSomething`
would match `@Get`. Prefer `TypeChecker` over string matching in anything new you write.

---

## Emitting code

Two styles coexist:

**`code_builder` AST** — preferred for structure:

```dart
final repository = Class((b) => b
  ..name = "_$className"
  ..implements.add(refer(className))
  ..methods.addAll(methods));

return DartFormatter().format('${repository.accept(DartEmitter())}');
```

**Raw string bodies** — used for method bodies, since `code_builder` has no statement
AST:

```dart
..body = Code("""
final _log = DragonflyLogManager.instance;
...
""")
```

Always run output through `DartFormatter().format(...)`. If formatting throws, the code
is syntactically invalid — `InjectableConfigGenerator` catches this and logs a warning
via `log.warning`, which is the right pattern to copy.

---

## Error handling: the trap

Nearly every generator does this:

```dart
try {
  … all the work …
} catch (e) {
  print("====>>>>>>>>> error on repository generator ${e}");
  return "";                     // <-- empty output, build still "succeeds"
}
```

`RepositoryVisitor.visitMethodElement` does the same per method, so **one bad method
silently vanishes from the generated repository** while the others generate fine.

This means:

- `build_runner` printing `Succeeded after 11.7s with 38 outputs` tells you nothing
  about correctness.
- The only error trace is a `print` line in the build log.
- `dart analyze` on `example/` is the actual regression test.

When writing a new generator, prefer letting the exception propagate, or at minimum use
`log.severe(...)` from `package:build` rather than `print`, so the failure is visible as
a build error. Do not copy the `return ""` pattern into new code.

---

## Adding a generator

See `.claude/skills/dragonfly-codegen/SKILL.md` for the full checklist.
