# Dependencies

## Runtime packages

### `dragonfly` (Flutter package)

| Dependency | Why |
|-----------|-----|
| `flutter` SDK | Widgets (`StatelessWidget`, `StatefulWidget`, `SizedBox`, `InheritedWidget`), `FutureBuilder`, foundation annotations (`@protected`, `@mustCallSuper`) |
| `http` | HTTP client used by `DragonflyNetworkHttpAdapter` and `AuthenticatedNetworkAdapter` |
| `collection` | `ListEquality` for `_ServiceKey` in DI container |

**Not depended on** (despite README claims in v1): `hive`, `hive_flutter`, `uuid`,
`fpdart`, `get_it`, `freezed`, `injectable`, `retrofit`, `bloc`, `json_serializable`,
`intl`. `Either` is hand-written. `HiveSessionStorage` duck-types a `dynamic _box`
so the consuming app owns the Hive dependency.

### `dragonfly_annotations` (pure Dart — no Flutter SDK)

| Dependency | Why |
|-----------|-----|
| `meta` | `@immutable`, `@protected`, `@Target`, `@TargetKind` for annotation classes |
| `meta_meta` | Required by `@Target` on annotation classes |

**No Flutter dependency.** The annotations package is pure Dart so the builder can
track a modern analyzer version without the Flutter SDK pin (see analyzer cap below).

### `dragonfly_builder` (pure Dart — no Flutter SDK)

| Dependency | Why |
|-----------|-----|
| `analyzer ^6.0.0` (resolved: `8.4.1`) | Dart element model, type system, AST visitor |
| `source_gen ^4.2.4` | `GeneratorForAnnotation`, `PartBuilder`, `LibraryBuilder`, `TypeChecker`, `ConstantReader`, `LibraryReader` |
| `build ^4.0.7` | `Builder`, `BuildStep`, `BuilderOptions`, `AssetId`, build system integration |
| `build_runner ^2.15.1` | dev dependency — CLI tool that orchestrates builders |
| `dart_style ^3.1.0` (resolved: `3.1.3`) | Formats generated Dart code |
| `code_builder ^4.11.1` | Programmatic Dart code generation (Method, Class, Parameter nodes) for repositories and models |
| `glob` | File-pattern matching for scanner generators (injectable config, router, component barrel) |
| `collection` | `ListEquality` for model comparisons |
| `dragonfly_annotations` | Reads annotation classes at build time |

**No Flutter dependency.** The builder never imports `package:dragonfly` — it emits
references to runtime types as string literals.

### `example` (Flutter app — integration test)

| Dependency | Why |
|-----------|-----|
| `flutter` SDK | The app itself |
| `dragonfly` | Path dependency — the framework under test |
| `dragonfly_annotations` | Path dependency — annotations used in example source files |
| `dragonfly_builder` | Dev dependency — runs code generation |
| `build_runner` | Dev dependency — orchestrates the build |

The example is the **only integration test**. Every API change must be exercised in
`example/lib/components/characters/` (the reference implementation) or `auth/`
(form-validation demo). There is no separate test harness for generated output.

---

## Dependency direction (strict)

```
dragonfly_builder ──▶ dragonfly_annotations ◀── dragonfly
                                                    ▲
example ────────────────────────────────────────────┘
```

- `dragonfly_builder` must **never** import `package:dragonfly`
- `dragonfly_annotations` imports nothing from `dragonfly` or `dragonfly_builder`
- `dragonfly` imports nothing from `dragonfly_builder` (runtime has no build-time dependency)
- `example` imports all three

The direction is enforced by convention, not by a build check. If a builder wants
to reference a runtime type, it emits a string literal.

---

## Analyzer version cap

`analyzer` is capped at 8.x **not by choice** but by the Flutter SDK:

- Flutter SDK pins `meta 1.18.0`
- `analyzer >=13.1.0` requires `meta ^1.18.3`
- `dart_style >=3.1.12` and `build >=4.0.8` both require `analyzer >=13.1.0`

Therefore:
- `dragonfly_builder/pubspec.yaml` declares `analyzer: ^6.0.0` (resolves to `8.4.1`)
- `build` is pinned `>=4.0.0 <4.0.8`
- `dart_style` is pinned `^3.1.0`

Raising any of these resolves fine in `dragonfly_builder` alone but makes
`example/` — and every consuming Flutter app — fail version solving. Revisit when
the Flutter SDK ships `meta >=1.18.3`.
