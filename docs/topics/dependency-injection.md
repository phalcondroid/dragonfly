# Dependency Injection

The DI container is a hand-written `get_it` replacement (`DragonflyContainer`,
`framework/di/`). It supports singleton, lazy-singleton, factory, async, factory-param,
scoped registrations, and a `reset()` method for tests.

### Registration (generated)

```dart
// components/<c>/config/injector.dart
import 'injector.config.dart';

@InjectableInit()
Future<void> initDragonflyContainer() async {
  DragonflyContainer.I.configureDependencies();
}
```

The generated `.config.dart` registers dependencies discovered by the visitor.
A `@StateManager` produces **two** registrations:

```dart
// Delegate — factory, re-resolved on each get
gh.registerFactory<CharacterStateManager>(
    () => CharacterStateManager(gh.get<GetUserListUseCase>(instanceName: 'GetUserList')));

// Controller — lazy singleton, shared across the app, disposed on scope pop
gh.registerLazySingleton<$CharacterStateManagerController>(
    () => $CharacterStateManagerController(gh.get<CharacterStateManager>()),
    dispose: (instance) => instance.dispose());
```

### Registering manually

```dart
DragonflyContainer.I.registerSingleton<MyService>(MyService());
DragonflyContainer.I.registerLazySingleton<MyRepo>(() => MyRepo());
DragonflyContainer.I.registerFactory<MyWidget>(() => MyWidget());
```

### Resolving

```dart
final svc = DragonflyContainer.I.get<MyService>();
final named = DragonflyContainer.I.get<MyService>(instanceName: 'alternative');
```

### Scopes

```dart
DragonflyContainer.I.pushNewScope();
// ... register scoped deps ...
await DragonflyContainer.I.popScope();   // disposes everything in the scope
```

Duplicates throw `DragonflyException` (get_it semantics). Set
`allowReassignment = true` to override.

## Component barrel

A barrel file is generated automatically next to each injector, re-exporting every
model, state, state manager, repository and form in the component:

```
lib/components/characters/config/injector.dragonfly.dart
```

One import pulls in the entire component:

```dart
import 'injector.dragonfly.dart';
```

Screens are excluded (their generated view mixins may conflict when several screens
bind the same manager). Consumers preferring individual imports override the
`component_generator` builder in `build.yaml`.

[← Back to README.md](../../README.md)
