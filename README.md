# 🐉 Dragonfly Framework

A powerful, opinionated Flutter framework for building scalable mobile applications with clean architecture, dependency injection, and reactive state management.

## 📦 Packages

| Package | Description |
|---------|-------------|
| `dragonfly` | Core framework with DI, state management, and utilities |
| `dragonfly_annotations` | Annotations for code generation |
| `dragonfly_builder` | Code generators for models, features, and DI |

---

## 🚀 Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  dragonfly:
    path: ../dragonfly
  dragonfly_annotations:
    path: ../dragonfly_annotations

dev_dependencies:
  build_runner: ^2.4.0
  dragonfly_builder:
    path: ../dragonfly_builder
```

### 2. Initialize the Framework

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Dragonfly
  DragonflyApp(config: AppConfig()).init();
  await initDragonflyContainer();
  
  runApp(const MyApp());
}
```

### 3. Run Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐  │
│  │   Screen    │───▶│   Feature   │───▶│     State       │  │
│  │  (Widget)   │◀───│  (Actions)  │◀───│  (Immutable)    │  │
│  └─────────────┘    └─────────────┘    └─────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       Domain Layer                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                      Use Cases                           ││
│  │         Business logic, data transformation              ││
│  └─────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│                        Data Layer                            │
│  ┌─────────────────┐              ┌─────────────────────┐   │
│  │   Repository    │─────────────▶│      Models         │   │
│  │  (API calls)    │              │  (JSON mapping)     │   │
│  └─────────────────┘              └─────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Feature System (Recommended)

The Feature pattern is Dragonfly's modern approach to state management, combining state, actions, and side effects in one cohesive unit.

### Creating a Feature

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character_feature.feature.dart';

@DragonflyFeature(logging: true)
class CharacterFeature extends Feature<CharacterState>
    with _$CharacterFeatureMixin {
  
  CharacterFeature(this._getCharacterUseCase)
      : super(const CharacterState.initial());

  final GetCharacterUseCase _getCharacterUseCase;

  @FeatureAction()
  Future<void> fetchCharacter(int id) async {
    emit(const CharacterState.loading());
    
    final result = await _getCharacterUseCase.call(id);
    
    result.fold(
      (error) => emit(CharacterState.error(message: error.toString())),
      (character) => emit(CharacterState.loaded(character: character)),
    );
  }

  @FeatureAction()
  void reset() => emit(const CharacterState.initial());
}
```

### Using in a Screen

```dart
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feature = context.feature<CharacterFeature>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => feature.fetchCharacter(1), // Direct call!
          ),
        ],
      ),
      body: FeatureBuilder<CharacterFeature, CharacterState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Text('Tap refresh to load'),
            loading: () => const CircularProgressIndicator(),
            loaded: (character) => Text(character.name),
            error: (message) => Text('Error: $message'),
          );
        },
      ),
    );
  }
}
```

### Feature Annotations

| Annotation | Description |
|------------|-------------|
| `@DragonflyFeature()` | Marks a class as a Feature |
| `@FeatureAction()` | Marks a method as a user action |
| `@InitialState()` | Marks the initial state getter |
| `@SideEffect()` | Marks a method as a side effect |
| `@Computed()` | Marks a derived/computed property |

### Feature Options

```dart
@DragonflyFeature(
  logging: true,      // Enable state change logging
  injectable: true,   // Auto-register in DI container
  scope: 'user',      // DI scope
  order: 100,         // DI registration order
)
```

### Side Effects

```dart
@FeatureAction()
Future<void> deleteCharacter(Character character) async {
  emit(const CharacterState.loading());
  await _deleteUseCase.call(character.id);
  emit(const CharacterState.initial());
  
  // Emit side effects
  sideEffect(const ShowSnackbar('Character deleted'));
  sideEffect(const NavigateTo('/home'));
}
```

Built-in side effects:
- `ShowSnackbar(message)` - Show a snackbar
- `NavigateTo(route)` - Navigate to a route
- `ShowDialog(builder)` - Show a dialog
- `Pop([result])` - Pop the current route

Handle with `DefaultSideEffectHandler`:

```dart
DefaultSideEffectHandler<CharacterFeature>(
  child: const CharacterScreen(),
)
```

---

## 📊 State Models

### Creating a State

```dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character_state.state.dart';

@StateModel()
sealed class CharacterState with _$CharacterState {
  const CharacterState._();

  const factory CharacterState.initial() = CharacterStateInitial;
  const factory CharacterState.loading() = CharacterStateLoading;
  const factory CharacterState.loaded({required Character character}) = CharacterStateLoaded;
  const factory CharacterState.error({required String message}) = CharacterStateError;
}
```

### Generated Methods

```dart
// Pattern matching (exhaustive)
state.when(
  initial: () => /* ... */,
  loading: () => /* ... */,
  loaded: (character) => /* ... */,
  error: (message) => /* ... */,
);

// Optional pattern matching
state.maybeWhen(
  loaded: (character) => /* ... */,
  orElse: () => /* fallback */,
);

// Type-safe mapping
state.map(
  initial: (s) => /* CharacterStateInitial */,
  loading: (s) => /* CharacterStateLoading */,
  loaded: (s) => /* CharacterStateLoaded */,
  error: (s) => /* CharacterStateError */,
);
```

### State Options

```dart
@StateModel(
  copyWith: true,       // Generate copyWith method
  equals: true,         // Generate equality operators
  toStringMethod: true, // Generate toString
  whenMethods: true,    // Generate when/maybeWhen
  mapMethods: true,     // Generate map/maybeMap
)
```

---

## 📦 Data Models

### Creating a Model

```dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character.model.dart';

@FactoryModel()
abstract class Character implements _$CharacterContract {
  factory Character({
    required int id,
    required String name,
    required String status,
    @Field(field: 'image_url') required String image,
  }) = _$Character;

  factory Character.fromJson(Map<String, Object?> json) = _$Character.fromJson;
}
```

### Model Options

```dart
@FactoryModel(
  copyWith: true,       // Generate copyWith
  toJson: true,         // Generate toJson
  toMap: true,          // Generate toMap
  equals: true,         // Generate equality
  toStringMethod: true, // Generate toString
  generic: false,       // Enable generic support
)
```

### Field Annotations

```dart
@Field(
  field: 'json_key',    // Custom JSON key
  converTo: 'String',   // Type conversion
  value: defaultValue,  // Default value
  ignore: false,        // Ignore in serialization
  fromJson: true,       // Include in fromJson
  toJson: true,         // Include in toJson
)
```

### Generic Models

```dart
@FactoryModel(generic: true)
abstract class ServiceResponse<T> implements _$ServiceResponseContract<T> {
  factory ServiceResponse({
    required Info info,
    required List<T> results,
  }) = _$ServiceResponse<T>;

  factory ServiceResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) = _$ServiceResponse.fromJson;
}

// Usage
final response = ServiceResponse<Character>.fromJson(
  json,
  (e) => Character.fromJson(e as Map<String, Object?>),
);
```

---

## 💉 Dependency Injection

### Setting Up DI

```dart
// injector.dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'injector.config.dart';

@DragonflyInjectableInit()
Future<void> initDragonflyContainer() async {
  DragonflyContainer.I.configureDependencies();
}
```

### Registering Dependencies

#### Use Cases

```dart
@InjectableUseCase(
  as: UseCase<int, Error, Character>,  // Register as interface
  instanceName: 'GetCharacter',         // Named instance
)
class GetCharacterUseCase implements UseCase<int, Error, Character> {
  final CharacterRepository _repository;
  
  const GetCharacterUseCase(this._repository);
  
  @override
  Future<Either<Error, Character>> call(int id) async {
    return _repository.getCharacter(id);
  }
}
```

#### Repositories

```dart
@Repository(
  url: 'https://api.example.com',
  adapter: NetworkAdapter.http,
)
abstract class CharacterRepository {
  @Get(path: '/character/{id}')
  Future<Character> getCharacter(@Path('id') int id);
  
  @Get(path: '/character')
  Future<ServiceResponse<Character>> getCharacters(
    @Query('name') String name,
  );
  
  @Post(path: '/character')
  Future<Character> createCharacter(@Body() Character character);
}
```

### Injecting Dependencies

```dart
// Constructor injection
class CharacterFeature extends Feature<CharacterState> {
  CharacterFeature(this._useCase) : super(const CharacterState.initial());
  
  final GetCharacterUseCase _useCase;
}

// Named injection
class MyFeature extends Feature<MyState> {
  MyFeature(@Inject('GetCharacter') this._useCase)
      : super(const MyState.initial());
  
  final UseCase<int, Error, Character> _useCase;
}

// Manual injection
final useCase = DragonflyContainer.I.get<GetCharacterUseCase>();
final named = DragonflyContainer.I.get<UseCase>(instanceName: 'GetCharacter');
```

### DI Annotations

| Annotation | Scope | Description |
|------------|-------|-------------|
| `@InjectableUseCase()` | Factory | New instance each time |
| `@Repository()` | Lazy Singleton | Single instance, lazy created |
| `@DragonflyFeature()` | Factory | New instance each time |
| `@Singleton()` | Singleton | Single instance, eager |
| `@LazySingleton()` | Lazy Singleton | Single instance, lazy |

---

## 🌐 Network Layer

### Repository Methods

```dart
@Repository(url: 'https://api.example.com')
abstract class ApiRepository {
  
  @Get(path: '/users/{id}')
  Future<User> getUser(@Path('id') int id);
  
  @Get(path: '/users')
  Future<List<User>> getUsers(
    @Query('page') int page,
    @Query('limit') int limit,
  );
  
  @Post(path: '/users')
  Future<User> createUser(@Body() User user);
  
  @Put(path: '/users/{id}')
  Future<User> updateUser(
    @Path('id') int id,
    @Body() User user,
  );
  
  @Patch(path: '/users/{id}')
  Future<User> patchUser(
    @Path('id') int id,
    @Body() Map<String, dynamic> updates,
  );
  
  @Delete(path: '/users/{id}')
  Future<void> deleteUser(@Path('id') int id);
}
```

### HTTP Annotations

| Annotation | Description |
|------------|-------------|
| `@Get(path:)` | HTTP GET request |
| `@Post(path:)` | HTTP POST request |
| `@Put(path:)` | HTTP PUT request |
| `@Patch(path:)` | HTTP PATCH request |
| `@Delete(path:)` | HTTP DELETE request |
| `@Path('name')` | URL path parameter |
| `@Query('name')` | Query string parameter |
| `@Body()` | Request body |
| `@Header('name')` | Request header |

---

## 📋 Logging

Dragonfly includes a beautiful, colored logging system with full support for network request/response logging and repository operations.

### Basic Usage

```dart
import 'package:dragonfly/dragonfly.dart';

final log = DragonflyLogManager.instance;
// or use the shorthand
final log = dragonflyLog;

// Different log levels
log.debug('Detailed debug info');
log.info('General information');
log.success('Operation completed!', data: {'userId': '123'});
log.warning('This might be a problem');
log.error('Something went wrong', error: exception, stackTrace: stack);
log.danger('Critical failure!');
```

### Configuration

```dart
// In your main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DragonflyApp(
    config: AppConfig(),
    showBanner: true,        // Show the Dragonfly banner
    enableLogging: true,     // Enable/disable logging
    minLogLevel: DragonflyLogLevel.info, // Set minimum level
  ).init();

  runApp(const MyApp());
}

// Configure manually
final log = DragonflyLogManager.instance;
log.setEnabled(true);
log.setMinLevel(DragonflyLogLevel.debug);
log.enableHistory(maxSize: 500); // Keep log history
```

### Network Logging

Network requests and responses are automatically logged when using `DragonflyNetworkHttpAdapter`:

```
╭─────────────────────────────────────────────────────────╮
│ 📤 REQUEST  [ABC12345]                                  │
├─────────────────────────────────────────────────────────┤
│  GET     https://api.example.com/users                  │
├─ Headers                                                │
│    Content-Type: application/json                       │
│    Authorization: Bearer ***                            │
╰─────────────────────────────────────────────────────────╯

╭─────────────────────────────────────────────────────────╮
│ 📥 RESPONSE [ABC12345]                                  │
├─────────────────────────────────────────────────────────┤
│  ✅ 200 OK (145ms)                                      │
│  ← GET https://api.example.com/users                    │
├─ Response Body                                          │
│    {                                                    │
│      "users": [...]                                     │
│    }                                                    │
╰─────────────────────────────────────────────────────────╯
```

### Repository Logging

Repository operations are automatically logged with try/catch wrapping:

```
╭───────────────────────────────────────────╮
│ ✅ SUCCESS  Repository                    │
├───────────────────────────────────────────┤
│  UserRepository.getUser()                 │
│  ⏱️  234ms                                │
├─ Parameters                               │
│    userId: 123                            │
├─ Message                                  │
│  Operation completed successfully         │
╰───────────────────────────────────────────╯
```

### Custom Log Listeners

```dart
// Add custom log listener
dragonflyLog.addListener((entry) {
  // Send to analytics
  analytics.trackEvent('log', {
    'level': entry.level.name,
    'message': entry.message,
  });

  // Or send to crash reporting
  if (entry.level == DragonflyLogLevel.error) {
    crashlytics.recordError(entry.error, entry.stackTrace);
  }
});

// Stream-based listening
dragonflyLog.logStream.listen((entry) {
  // Process log entries
});
```

### Log Levels

| Level | Icon | Usage |
|-------|------|-------|
| `debug` | 🔍 | Detailed debugging information |
| `info` | ℹ️ | General information |
| `success` | ✅ | Successful operations |
| `warning` | ⚠️ | Warnings and potential issues |
| `error` | ❌ | Recoverable errors |
| `danger` | 🔥 | Critical/fatal errors |
| `request` | 📤 | HTTP requests |
| `response` | 📥 | HTTP responses |

### Design

Dragonfly logs use beautiful **Unicode box-drawing characters** and **emoji icons** for visual clarity in any terminal or debug console, without relying on ANSI color codes for maximum compatibility.

---

## 🔧 Utilities

### Either Type

```dart
import 'package:dragonfly/dragonfly.dart';

// Create an Either
Either<Error, User> result = Right(user);  // Success
Either<Error, User> result = Left(error);  // Failure

// Handle result
result.fold(
  (error) => print('Error: $error'),
  (user) => print('User: ${user.name}'),
);

// Check type
if (result.isRight) {
  final user = result.getOrElse(() => defaultUser);
}
```

### JSON Datatype Mapper

```dart
import 'package:dragonfly/dragonfly.dart';

// Safe type mapping
final name = JsonDatatypeMapper.mapFor<String>(json, 'name');
final age = JsonDatatypeMapper.mapFor<int>(json, 'age', defaultValue: 0);

// Nested objects
final user = JsonDatatypeMapper.mapNestedObject<User>(
  json, 'user', User.fromJson,
);

// Lists
final items = JsonDatatypeMapper.mapGenericList<Item>(
  json['items'] as List?,
  (e) => Item.fromJson(e as Map<String, Object?>),
);

// Generic type parameters
final data = JsonDatatypeMapper.mapForTypeParameter<T>(
  json, 'data', fromJsonT,
);
```

---

## 📁 Project Structure

```
lib/
├── components/
│   └── [feature_name]/
│       ├── config/
│       │   ├── injector.dart
│       │   └── injector.config.dart (generated)
│       ├── data/
│       │   ├── models/
│       │   │   └── [model].dart
│       │   └── repositories/
│       │       └── [repository].dart
│       ├── domain/
│       │   └── use_cases/
│       │       └── [use_case].dart
│       └── presentation/
│           ├── features/
│           │   └── [feature].dart
│           ├── screens/
│           │   └── [screen].dart
│           └── states/
│               └── [state].dart
└── main.dart
```

---

## 🔄 Migration from BLoC

| BLoC Pattern | Dragonfly Feature |
|--------------|-------------------|
| `Event` class | `@FeatureAction()` methods |
| `State` class | Same `@StateModel()` |
| `Bloc` class | `Feature<S>` class |
| `BlocBuilder` | `FeatureBuilder` |
| `BlocListener` | `FeatureListener` |
| `context.read<Bloc>().add(Event)` | `feature.methodName()` |

---

## 📝 Code Generation Commands

```bash
# Build once
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild on changes)
dart run build_runner watch --delete-conflicting-outputs

# Clean generated files
dart run build_runner clean
```

---

## 🎨 Best Practices

1. **One Feature per screen** - Keep features focused and single-responsibility
2. **Use sealed states** - Exhaustive pattern matching prevents bugs
3. **Side effects for navigation** - Don't navigate directly in features
4. **Named DI for interfaces** - Use `instanceName` when registering interfaces
5. **Keep actions simple** - Delegate complex logic to use cases

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with 🔥 by the Dragonfly Team
</p>
