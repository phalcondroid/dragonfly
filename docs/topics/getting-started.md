# Getting Started

An overview of the Dragonfly framework packages, architecture, setup, project layout, build pipeline, debugging, and troubleshooting.

## Packages

| Package | Role | Dependencies |
|---------|------|-------------|
| `dragonfly` | Runtime: DI container, network, state management, session, logging, forms | Flutter SDK |
| `dragonfly_annotations` | Annotation classes only — no logic, no Flutter | `meta` |
| `dragonfly_builder` | `source_gen` builders that read those annotations | `analyzer`, `source_gen`, `build` |

Strict dependency direction:
```
dragonfly_builder ──▶ dragonfly_annotations ◀── dragonfly
                                                    ▲
example ────────────────────────────────────────────┘
```

`dragonfly_builder` must **never** import `package:dragonfly`. It emits references to
runtime types as string literals.

## Architecture

Data flows one direction through four layers:

```
Screen (Widget)                @Screen, @StateView + $Manager mixin
    │  dispatch events, rebuild from state
    ▼
State Manager (plain class)    @StateManager, @Event methods returning values
    │  business logic, orchestrates use cases
    ▼
Use Case (plain class)         @UseCase, hand-written call method
    │  data transformation, returns Either<Error, T>
    ▼
Repository (abstract)          @Repository, generated HTTP / realtime client
    │  network calls, model deserialization
    ▼
Network Adapter (runtime)      DragonflyBaseNetworkAdapter, HTTP & WebSocket
```

Every layer is generated except the state manager delegate and the use case body.
Models, repository implementations, state sealed classes, controllers, view mixins,
DI configuration and router configuration are all build outputs.

## Getting started

### 1. Dependencies

```yaml
# pubspec.yaml
dependencies:
  dragonfly:
    path: ../dragonfly
  dragonfly_annotations:
    path: ../dragonfly_annotations

dev_dependencies:
  build_runner: ^2.15.0
  dragonfly_builder:
    path: ../dragonfly_builder
```

### 2. App bootstrap

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DragonflyApp(config: AppConfig()).init();
  runApp(const MyApp());
}
```

### 3. Build

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze     # the real pass/fail signal — never trust build_runner alone
```

> **Warning:** Nearly every generator swallows its own exceptions
> (`catch (e) { print(...); return ""; }`). `build_runner` reports `Succeeded`
> while writing an **empty or partial file**. `dart analyze` is always the
> gate. Grep the build log for `====>>` to find hidden crashes.

### 4. Verify

```bash
dart analyze
dart run build_runner build
```

Both commands must pass. Generated files are committed to the repo — comparing
`git diff` against the last known-good output is a fast way to catch silent
failures.

## Project layout

```
lib/
├── components/
│   ├── <component>/
│   │   ├── config/
│   │   │   ├── app_config.dart         DragonflyConfig subclass
│   │   │   ├── injector.dart           @InjectableInit anchor + .config.dart
│   │   │   └── injector.dragonfly.dart  component barrel (generated)
│   │   ├── data/
│   │   │   ├── models/                 @FactoryModel  → .model.dart
│   │   │   └── repositories/           @Repository    → .repository.dart
│   │   ├── domain/
│   │   │   ├── use_cases/              @UseCase       → .config.dart registration
│   │   │   └── forms/                  @FormSchema    → .form.dart
│   │   ├── exceptions/
│   │   └── presentation/
│   │       ├── states/                 @StateModel    → .state.dart
│   │       ├── features/               @StateManager  → .state_manager.dart
│   │       └── screens/                @Screen + @StateView → .view.dart
│   └── ...
├── config/
│   └── router_config.dart              @RouterConfig   → .router.dart
└── main.dart
```

## Build & verify

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

**The trap:** `build_runner` reports `Succeeded` even when a generator throws and
returns an empty file. The real error is buried in the build log (grep for `====>>`
and `error on`). Always verify with `dart analyze` and by reading the generated
file to confirm it contains real content, not just a header.

## Debugging

```dart
// Print every registered dependency across all scopes:
DragonflyContainer.I.debugPrintRegisteredInstances();

// Check a specific registration:
DragonflyContainer.I.isRegistered<MyService>(instanceName: 'alt');

// Verify async singletons are done:
await DragonflyContainer.I.allReady();
if (DragonflyContainer.I.allReadySync()) { ... }
```

### Missing dependency in `injector.config.dart`

If an annotated class does not appear in the generated config, another file in
`lib/` fails to compile. The DI scanner silently skips unresolvable libraries.
Fix that file, rebuild, and the dependency appears.

### Stale generated output

Generated files in this repo are committed. A stale file from a previous build
can mislead. Before drawing conclusions from one, regenerate with
`--delete-conflicting-outputs` and compare `git diff`.

## Troubleshooting

| Symptom | Cause |
|---------|-------|
| Generated file missing | Missing `part '…'` directive, or annotation not imported |
| Generated file empty | Generator threw; grep the build log for `====>>` / `error on` |
| Undefined name in a generated part | Source file is missing a required import (see per-annotation import requirements) |
| Dependency missing from `injector.config.dart` | Another file in `lib/` fails to compile — the scanner skips it silently |
| Duplicate registration exception | Same type+name registered twice. Set `allowReassignment = true` to override |
| `build_runner` reports success, `dart analyze` fails | Generators swallow exceptions — always analyze after building |
| `InvalidType` in generated code | Type declared in another generated file — rebuild once more (stale output) |
| `@View` not found / ambiguous | Use `@StateView` — Flutter exports its own `View` widget via `material` |

---

[Back to README.md](../../README.md)
