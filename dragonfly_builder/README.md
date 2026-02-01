# Dragonfly Builder

Code generation package for the Dragonfly framework. Provides generators for creating:

- **Factory Models** - Data layer models with JSON serialization support
- **Event Models** - Sealed event classes for BLoC pattern
- **State Models** - Sealed state classes for BLoC pattern
- **Repository implementations** - Network repository code generation
- **Dependency injection configuration** - Injectable config generation

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dragonfly: ^1.0.0
  dragonfly_annotations: ^1.0.0

dev_dependencies:
  dragonfly_builder: ^1.0.0
  build_runner: ^2.4.0
```

## Usage

### Factory Model (@FactoryModel)

Use `@FactoryModel` for data layer models that need JSON serialization.

```dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';

part 'user.model.dart';

@FactoryModel(
  toJson: true,      // Generate toJson method
  toMap: true,       // Generate toMap method  
  equals: true,      // Generate == and hashCode
  toStringMethod: true, // Generate toString
  copyWith: false,   // Generate copyWith (default: false)
)
abstract interface class User implements _$UserContract {
  factory User({
    @Field(field: 'user_id', value: 0) required int id,
    required String name,
    required String email,
    String? phone,
  }) = _$User;

  factory User.fromJson(Map<String, Object?> json) = _$User.fromJson;
}
```

#### Generic Models

For models with generic type parameters:

```dart
@FactoryModel(generic: true)
abstract interface class ServiceResponse<T> implements _$ServiceResponseContract<T> {
  factory ServiceResponse({
    required Info info,
    required List<T> results,
  }) = _$ServiceResponse;

  factory ServiceResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) = _$ServiceResponse.fromJson;
}

// Multiple generic parameters
@FactoryModel(generic: true)
abstract interface class PaginatedResponse<I, T> 
    implements _$PaginatedResponseContract<I, T> {
  factory PaginatedResponse({
    required I info,
    required List<T> results,
  }) = _$PaginatedResponse;

  factory PaginatedResponse.fromJson(
    Map<String, Object?> json,
    I Function(Object? json) fromJsonI,
    T Function(Object? json) fromJsonT,
  ) = _$PaginatedResponse.fromJson;
}

// Usage
final response = ServiceResponse<Character>.fromJson(
  json,
  (e) => Character.fromJson(e as Map<String, Object?>),
);
```

### Event Model (@EventModel)

Use `@EventModel` for BLoC event classes.

```dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'user_event.event.dart';

@EventModel(
  equals: true,          // Generate == and hashCode
  toStringMethod: true,  // Generate toString
  copyWith: true,        // Generate copyWith
  whenMethods: true,     // Generate when/maybeWhen
  mapMethods: true,      // Generate map/maybeMap
)
sealed class UserEvent with _$UserEvent {
  const UserEvent._();

  const factory UserEvent.loading() = UserEventLoading;
  const factory UserEvent.fetchUser({required int userId}) = UserEventFetchUser;
  const factory UserEvent.deleteUser({required User user}) = UserEventDeleteUser;
}
```

**Pattern matching:**

```dart
// Using when - all cases required
event.when(
  loading: () => print('Loading...'),
  fetchUser: (userId) => print('Fetching user $userId'),
  deleteUser: (user) => print('Deleting ${user.name}'),
);

// Using maybeWhen - orElse fallback
event.maybeWhen(
  loading: () => print('Loading...'),
  orElse: () => print('Other event'),
);

// Using map - type-safe with access to the event instance
final widget = event.map(
  loading: (e) => CircularProgressIndicator(),
  fetchUser: (e) => Text('Fetching ${e.userId}'),
  deleteUser: (e) => Text('Deleting ${e.user.name}'),
);
```

### State Model (@StateModel)

Use `@StateModel` for BLoC state classes.

```dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'user_state.state.dart';

@StateModel(
  copyWith: true,        // Generate copyWith
  equals: true,          // Generate == and hashCode
  toStringMethod: true,  // Generate toString
  whenMethods: true,     // Generate when/maybeWhen
  mapMethods: true,      // Generate map/maybeMap
  toJson: false,         // Generate toJson (default: false)
  toMap: false,          // Generate toMap (default: false)
)
sealed class UserState with _$UserState {
  const UserState._();

  const factory UserState.initial() = UserStateInitial;
  const factory UserState.loading() = UserStateLoading;
  const factory UserState.loaded({required User user}) = UserStateLoaded;
  const factory UserState.error({required String message}) = UserStateError;
}
```

**Usage in BLoC:**

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(const UserState.initial()) {
    on<UserEventFetchUser>(_onFetchUser);
  }

  Future<void> _onFetchUser(
    UserEventFetchUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserState.loading());
    try {
      final user = await userRepository.getUser(event.userId);
      emit(UserState.loaded(user: user));
    } catch (e) {
      emit(UserState.error(message: e.toString()));
    }
  }
}

// In UI
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    return state.when(
      initial: () => const Text('Welcome'),
      loading: () => const CircularProgressIndicator(),
      loaded: (user) => Text('Hello ${user.name}'),
      error: (message) => Text('Error: $message'),
    );
  },
);
```

### Field Annotation (@Field)

Customize field mapping in factory models:

```dart
@FactoryModel()
abstract interface class User implements _$UserContract {
  factory User({
    @Field(field: 'user_id') required int id,         // Map from 'user_id' key
    @Field(value: 'Unknown') String? name,            // Default value
    @Field(field: 'created_at') required String createdAt,
    @Field(ignore: true) String? localCache,          // Ignore in serialization
  }) = _$User;
}
```

## Running Code Generation

```bash
# One-time generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch --delete-conflicting-outputs
```

## Generated File Extensions

| Annotation | Output Extension |
|------------|------------------|
| `@FactoryModel` | `.model.dart` |
| `@EventModel` | `.event.dart` |
| `@StateModel` | `.state.dart` |
| `@Repository` | `.repository.dart` |
| `@DragonflyInjectableInit` | `.config.dart` |

## JsonDatatypeMapper

The `JsonDatatypeMapper` class provides utilities for safe JSON mapping:

```dart
// Map primitive types
final name = JsonDatatypeMapper.mapForGeneric<String>(json, 'name');
final age = JsonDatatypeMapper.mapForGeneric<int>(json, 'age', defaultValue: 0);

// Map lists
final tags = JsonDatatypeMapper.mapGenericList<String>(
  json['tags'] as List?,
  (e) => e as String,
);

// Map nested objects
final address = JsonDatatypeMapper.mapNestedObject<Address>(
  json,
  'address',
  (map) => Address.fromJson(map),
);

// Map nullable nested objects
final profile = JsonDatatypeMapper.mapNullableNestedObject<Profile>(
  json,
  'profile',
  (map) => Profile.fromJson(map),
);
```

## License

MIT
