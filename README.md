# 🐉 Dragonfly Framework

A powerful, opinionated Flutter framework for building scalable mobile applications with clean architecture, dependency injection, reactive state management, **session management**, and **access control (ACL)**.

## ✨ Key Features

- 🎯 **Feature-based State Management** - Combine state, actions, and side effects in one cohesive unit
- 💉 **Dependency Injection** - Automatic registration with scopes and named instances
- 🔐 **Session Management** - Built-in authentication with token handling
- 🛡️ **Access Control (ACL)** - Role and permission-based route protection
- 🛣️ **Declarative Routing** - Type-safe routes with automatic provider injection
- 📝 **Form Validation** - Schema-based validation with 30+ built-in validators
- 🌐 **Network Layer** - Repository pattern with automatic serialization
- 📋 **Beautiful Logging** - Formatted logs with emoji icons and network tracing
- ⚡ **Code Generation** - Generate models, states, repositories, forms, and DI config

## 📦 Packages

| Package | Description |
|---------|-------------|
| `dragonfly` | Core framework with DI, state management, session, and utilities |
| `dragonfly_annotations` | Annotations for code generation |
| `dragonfly_builder` | Code generators for models, features, routing, and DI |

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

## 🎯 Feature System (State Manager)

The Feature pattern is Dragonfly's modern approach to state management, combining state, actions, and side effects in one cohesive unit.

### Creating a Feature

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character_feature.state_manager.dart';

@DragonflyStateManager(logging: true)
class CharacterFeature extends Feature<CharacterState>
    with _$CharacterFeatureMixin {
  
  CharacterFeature(this._getCharacterUseCase)
      : super(const CharacterState.initial());

  final GetCharacterUseCase _getCharacterUseCase;

  @StateAction()
  Future<void> fetchCharacter(int id) async {
    emit(const CharacterState.loading());
    
    final result = await _getCharacterUseCase.call(id);
    
    result.fold(
      (error) => emit(CharacterState.error(message: error.toString())),
      (character) => emit(CharacterState.loaded(character: character)),
    );
  }

  @StateAction()
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
| `@DragonflyStateManager()` | Marks a class as a Feature (State Manager) |
| `@StateAction()` | Marks a method as a user action |
| `@InitialState()` | Marks the initial state getter |
| `@SideEffect()` | Marks a method as a side effect |
| `@Computed()` | Marks a derived/computed property |

### Feature Options

```dart
@DragonflyStateManager(
  logging: true,      // Enable state change logging
  injectable: true,   // Auto-register in DI container
  scope: 'user',      // DI scope
  order: 100,         // DI registration order
)
```

### Side Effects

```dart
@StateAction()
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
| `@DragonflyStateManager()` | Factory | New instance each time |
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

## 🛣️ Routing & Navigation

Dragonfly provides a powerful routing system with built-in session management and access control.

### Defining Routes

Use the `@DragonflyScreen` annotation to define routes:

```dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

// Public screen (no authentication required)
@DragonflyScreen(
  path: '/login',
  name: 'login',
  access: AccessLevel.guest,
)
class LoginScreen extends StatelessWidget { ... }

// Protected screen (authentication required)
@DragonflyScreen(
  path: '/home',
  name: 'home',
  initial: true,
  access: AccessLevel.authenticated,
  provider: HomeFeature,
)
class HomeScreen extends StatelessWidget { ... }

// Role-based access
@DragonflyScreen(
  path: '/admin',
  name: 'admin',
  access: AccessLevel.rolesRequired,
  roles: ['admin', 'superadmin'],
  provider: AdminFeature,
)
class AdminScreen extends StatelessWidget { ... }

// Permission-based access
@DragonflyScreen(
  path: '/reports',
  access: AccessLevel.permissionsRequired,
  permissions: ['view_reports', 'export_data'],
)
class ReportsScreen extends StatelessWidget { ... }
```

### Router Configuration

```dart
// config/router_config.dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'router_config.router.dart';

@DragonflyRouterConfig()
class AppRouterConfig with $AppRouterConfig {}

// main.dart
class MyApp extends StatelessWidget {
  static final _router = AppRouterConfig();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: _router.initialRoute,
    );
  }
}
```

### Screen Options

| Option | Description |
|--------|-------------|
| `path` | Route path (e.g., `/home`, `/user/:id`) |
| `name` | Named route identifier |
| `initial` | Is this the initial route? |
| `transition` | Screen transition animation |
| `provider` | Feature to inject automatically |
| `access` | Access level (guest, authenticated, roles, permissions) |
| `roles` | Required roles for access |
| `permissions` | Required permissions for access |
| `redirectOnDenied` | Custom redirect when unauthorized |
| `redirectOnUnauthenticated` | Custom redirect when not logged in |

### Transitions

```dart
@DragonflyScreen(
  path: '/details',
  transition: ScreenTransition.slideRight,
)
```

Available transitions:
- `ScreenTransition.fade` (default)
- `ScreenTransition.slideRight`
- `ScreenTransition.slideUp`
- `ScreenTransition.scale`
- `ScreenTransition.none`
- `ScreenTransition.platform`

### Navigation Helpers

```dart
// Generated methods in router mixin
_router.navigateTo(context, 'home');
_router.navigateToPath(context, '/user/123');
_router.replaceTo(context, 'login');
_router.resetTo(context, 'home');
_router.navigateToHome(context);  // After login
_router.navigateToLogin(context); // After logout
```

---

## 🔐 Session Management

Dragonfly includes a comprehensive session manager for handling authentication, tokens, and access control.

### Initialization

```dart
import 'package:dragonfly/dragonfly.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize session manager
  await DragonflySessionManager.instance.init(
    config: DragonflySessionConfiguration(
      loginPath: '/login',
      homePath: '/home',
      unauthorizedPath: '/unauthorized',
      tokenType: 'Bearer',
      sessionTimeout: const Duration(hours: 24),
      persistSession: true,
    ),
    storage: HiveSessionStorage(await Hive.openBox('session')),
  );

  // Initialize the app
  await DragonflyApp(config: AppConfig()).init();
  
  runApp(const MyApp());
}
```

### Login & Logout

```dart
// Login with user data, roles, and permissions
await dragonflySession.login<User>(
  token: response.accessToken,
  user: response.user,
  roles: ['user', 'premium'],
  permissions: ['read', 'write', 'delete'],
  expiresIn: const Duration(hours: 24),
);

// Logout
await dragonflySession.logout();
```

### Checking Session State

```dart
// Check authentication
if (dragonflySession.isAuthenticated) {
  // User is logged in
}

// Get current user
final user = dragonflySession.getUser<User>(User.fromJson);

// Get user field
final email = dragonflySession.getUserField<String>('email');

// Get token for API calls
final token = dragonflySession.token;
final authHeader = dragonflySession.authorizationHeader; // "Bearer <token>"
```

### Listening to Session Changes

```dart
// Stream-based listening
dragonflySession.stateStream.listen((state) {
  switch (state) {
    case SessionState.authenticated:
      print('User logged in');
      break;
    case SessionState.unauthenticated:
      print('User logged out');
      break;
    case SessionState.expired:
      print('Session expired');
      break;
    case SessionState.loading:
      print('Restoring session...');
      break;
  }
});

// Callback-based listening
dragonflySession.addStateListener((state) {
  // Handle state change
});
```

### Session Storage Options

```dart
// In-memory (for testing, non-persistent)
await DragonflySessionManager.instance.init(
  storage: InMemorySessionStorage(),
);

// Hive (encrypted, persistent)
await DragonflySessionManager.instance.init(
  storage: HiveSessionStorage(await Hive.openBox('session')),
);

// Custom storage (implement SessionStorage interface)
class SecureSessionStorage implements SessionStorage {
  @override
  Future<String?> getString(String key) async { ... }
  @override
  Future<void> setString(String key, String value) async { ... }
  // ... implement other methods
}
```

---

## 🛡️ Access Control List (ACL)

Dragonfly provides role-based (RBAC) and permission-based access control.

### Access Levels

| Level | Description |
|-------|-------------|
| `AccessLevel.guest` | Anyone can access |
| `AccessLevel.authenticated` | Must be logged in |
| `AccessLevel.rolesRequired` | Must have specific roles |
| `AccessLevel.permissionsRequired` | Must have specific permissions |

### Checking Access

```dart
// Check roles
if (dragonflySession.hasRole('admin')) { ... }
if (dragonflySession.hasAnyRole(['admin', 'moderator'])) { ... }
if (dragonflySession.hasAllRoles(['user', 'verified'])) { ... }

// Check permissions
if (dragonflySession.hasPermission('delete_users')) { ... }
if (dragonflySession.hasAnyPermission(['read', 'write'])) { ... }
if (dragonflySession.hasAllPermissions(['read', 'write', 'delete'])) { ... }
```

### Managing Roles & Permissions

```dart
// Add roles
await dragonflySession.addRoles(['premium', 'verified']);

// Remove roles
await dragonflySession.removeRoles(['trial']);

// Add permissions
await dragonflySession.addPermissions(['export_data']);

// Remove permissions
await dragonflySession.removePermissions(['delete_users']);
```

### Route Protection

Routes are automatically protected based on `@DragonflyScreen` annotations:

```dart
@DragonflyScreen(
  path: '/admin/users',
  access: AccessLevel.rolesRequired,
  roles: ['admin'],
  redirectOnDenied: '/unauthorized',
  redirectOnUnauthenticated: '/login',
)
class AdminUsersScreen extends StatelessWidget { ... }
```

When a user tries to access a protected route:
1. If not authenticated → Redirect to `loginPath`
2. If missing roles/permissions → Redirect to `unauthorizedPath`

### Handling Access Denied

```dart
await DragonflySessionManager.instance.init(
  config: DragonflySessionConfiguration(...),
  onAccessDenied: (reason, redirectPath) {
    print('Access denied: $reason');
    print('Redirecting to: $redirectPath');
    // Show snackbar, log analytics, etc.
  },
);
```

---

## 🔒 Authenticated API Requests

Dragonfly automatically injects authentication tokens into API requests.

### Using AuthenticatedNetworkAdapter

```dart
// Configure in DragonflyApp
DragonflyApp(
  networkConfig: DragonflyNetworkConfig(
    baseUrl: 'https://api.example.com',
  ),
).init();

// Register authenticated adapter
DragonflyContainer.I.registerLazySingleton<DragonflyBaseNetworkAdapter>(
  () => AuthenticatedNetworkAdapter(
    config: networkConfig,
    enableLogging: true,
    onTokenExpired: () async {
      // Handle 401 responses
      await dragonflySession.logout();
      // Navigate to login
    },
    refreshTokenCallback: () async {
      // Optionally refresh token before expiration
      return await authService.refreshToken();
    },
  ),
  instanceName: 'authenticatedNetwork',
);
```

### Authenticated Endpoints

```dart
@Repository(
  url: '/api',
  connection: 'authenticatedNetwork', // Use authenticated adapter
)
abstract class UserRepository {
  @Get(path: '/profile')
  @Authenticated() // Token will be added automatically
  Future<User> getProfile();

  @Post(path: '/login')
  // No @Authenticated - public endpoint
  Future<AuthResponse> login(@Body() LoginRequest request);
}
```

### Token Handling

The `AuthenticatedNetworkAdapter`:
- Automatically adds `Authorization: Bearer <token>` header
- Logs all requests/responses
- Handles 401 Unauthorized (calls `onTokenExpired`)
- Supports token refresh before expiration

---

## 📝 Form Validation

Dragonfly provides a powerful schema-based form validation system with code generation, integrated with StateManager.

### Defining a Form Schema

```dart
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'login_form.form.dart';

@FormSchema()
class LoginForm {
  @Required(message: 'Email is required')
  @Email(message: 'Please enter a valid email')
  final String email;

  @Required(message: 'Password is required')
  @MinLength(8, message: 'Password must be at least 8 characters')
  @StrongPassword(
    requireUppercase: true,
    requireLowercase: true,
    requireDigit: true,
  )
  final String password;

  @MustBeTrue(message: 'You must accept the terms')
  final bool acceptTerms;

  const LoginForm({
    this.email = '',
    this.password = '',
    this.acceptTerms = false,
  });
}
```

### Generated Code

The `@FormSchema` annotation generates:
- **`LoginFormState`** - Form state class tracking values, errors, and touched state
- **`LoginFormField`** - Enum of field names for type-safe references
- **`LoginFormFormController`** - Mixin for StateManager integration

### Available Validators

#### String Validators
| Validator | Description |
|-----------|-------------|
| `@Required()` | Field cannot be empty |
| `@Email()` | Valid email format |
| `@MinLength(n)` | Minimum string length |
| `@MaxLength(n)` | Maximum string length |
| `@Pattern(regex)` | Matches regex pattern |
| `@Url()` | Valid URL format |
| `@Phone()` | Valid phone number |
| `@Alpha()` | Only letters |
| `@Numeric()` | Only numbers |
| `@Alphanumeric()` | Letters and numbers only |

#### Number Validators
| Validator | Description |
|-----------|-------------|
| `@Min(n)` | Minimum value |
| `@Max(n)` | Maximum value |
| `@Range(min, max)` | Value within range |
| `@Positive()` | Must be positive |
| `@Negative()` | Must be negative |

#### Password Validators
| Validator | Description |
|-----------|-------------|
| `@StrongPassword()` | Configurable password strength |

```dart
@StrongPassword(
  minLength: 8,
  requireUppercase: true,
  requireLowercase: true,
  requireDigit: true,
  requireSpecial: false,
)
final String password;
```

#### Boolean Validators
| Validator | Description |
|-----------|-------------|
| `@MustBeTrue()` | Must be checked/true |
| `@MustBeFalse()` | Must be unchecked/false |

#### Date Validators
| Validator | Description |
|-----------|-------------|
| `@PastDate()` | Date must be in the past |
| `@FutureDate()` | Date must be in the future |
| `@MinAge(years)` | Minimum age requirement |

#### Collection Validators
| Validator | Description |
|-----------|-------------|
| `@MinItems(n)` | Minimum list items |
| `@MaxItems(n)` | Maximum list items |

#### Cross-Field Validators
| Validator | Description |
|-----------|-------------|
| `@EqualTo('field')` | Must equal another field |
| `@NotEqualTo('field')` | Must differ from another field |
| `@RequiredIf('field', value)` | Required when condition met |
| `@RequiredUnless('field', value)` | Required unless condition met |

#### Payment Validators
| Validator | Description |
|-----------|-------------|
| `@CreditCard()` | Valid credit card (Luhn) |
| `@Cvv()` | Valid CVV format |
| `@ExpiryDate()` | Valid and not expired |

### Integrating with StateManager

```dart
@DragonflyStateManager(logging: true)
class LoginStateManager extends StateManager<LoginState>
    with _$LoginStateManagerMixin, LoginFormFormController<LoginState> {
  
  LoginStateManager() : super(const LoginState.initial());

  // Required: Implement formState getter
  @override
  LoginFormState get formState => state.form;

  // Required: Implement updateFormState
  @override
  void updateFormState(LoginFormState newFormState) {
    emit(state.copyWith(form: newFormState));
  }

  // Generated methods available:
  // - updateEmail(String value)
  // - updatePassword(String value)
  // - updateAcceptTerms(bool value)
  // - touchEmail()
  // - touchPassword()
  // - touchAcceptTerms()
  // - validateAllFields() -> bool
  // - resetAllFields()

  @StateAction()
  Future<void> login() async {
    // Validate all fields first
    if (!validateAllFields()) {
      return; // Form has errors
    }

    emit(const LoginState.loading());
    // ... perform login
  }
}
```

### Using Validated Widgets

Dragonfly provides pre-built widgets that integrate with form validation:

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stateManager = context.stateManager<LoginStateManager>();

    return ValidatedForm(
      child: Column(
        children: [
          // Email field with auto-validation
          ValidatedTextField<LoginStateManager, LoginState>(
            fieldName: 'email',
            formSelector: (state) => state.form,
            onChanged: stateManager.updateEmail,
            onBlur: stateManager.touchEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // Password field
          ValidatedTextField<LoginStateManager, LoginState>(
            fieldName: 'password',
            formSelector: (state) => state.form,
            onChanged: stateManager.updatePassword,
            onBlur: stateManager.touchPassword,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),

          const SizedBox(height: 16),

          // Checkbox for terms
          ValidatedCheckbox<LoginStateManager, LoginState>(
            fieldName: 'acceptTerms',
            formSelector: (state) => state.form,
            onChanged: (v) => stateManager.updateAcceptTerms(v ?? false),
            title: const Text('I accept the terms and conditions'),
          ),

          const SizedBox(height: 24),

          // Submit button
          ValidatedSubmitButton<LoginStateManager, LoginState>(
            formSelector: (state) => state.form,
            onSubmit: stateManager.login,
            loadingSelector: (state) => state is LoginStateLoading,
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
```

### Available Validated Widgets

| Widget | Description |
|--------|-------------|
| `ValidatedTextField` | Text input with validation |
| `ValidatedDropdown` | Dropdown with validation |
| `ValidatedCheckbox` | Checkbox with validation |
| `ValidatedSwitch` | Switch with validation |
| `ValidatedDatePicker` | Date picker with validation |
| `ValidatedSubmitButton` | Submit button that disables when invalid |
| `ValidatedForm` | Form wrapper |

### Form Schema Options

```dart
@FormSchema(
  copyWith: true,         // Generate copyWith method
  validateOnChange: true, // Validate when value changes
  validateOnBlur: true,   // Validate when field loses focus
  stateName: 'MyFormState', // Custom state class name
)
```

### Field Metadata

Add display hints for form fields:

```dart
@FormField(
  label: 'Email Address',
  hint: 'Enter your email',
  helpText: 'We will never share your email',
  keyboardType: FormKeyboardType.emailAddress,
  obscureText: false,
  textCapitalization: FormTextCapitalization.none,
)
final String email;
```

### Manual Validation

```dart
// Validate all fields
if (stateManager.validateAllFields()) {
  // Form is valid, proceed
}

// Check individual field
final emailError = stateManager.formState.email.error;
final isEmailValid = stateManager.formState.email.isValid;
final isEmailTouched = stateManager.formState.email.touched;

// Check form state
final isFormValid = stateManager.formState.isValid;
final isDirty = stateManager.formState.isDirty;
final isTouched = stateManager.formState.isTouched;

// Get all values
final values = stateManager.formState.values; // Map<String, dynamic>

// Get all errors
final errors = stateManager.formState.activeErrors; // Map<String, String>
```

### Example: Registration Form with Cross-Field Validation

```dart
@FormSchema()
class RegistrationForm {
  @Required()
  @Email()
  final String email;

  @Required()
  @StrongPassword(requireSpecial: true)
  final String password;

  @Required()
  @EqualTo('password', message: 'Passwords do not match')
  final String confirmPassword;

  final bool isCompany;

  @RequiredIf('isCompany', true, message: 'Company name is required')
  @MinLength(2)
  final String companyName;

  @MinAge(18, message: 'You must be 18 or older')
  final DateTime? dateOfBirth;

  const RegistrationForm({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isCompany = false,
    this.companyName = '',
    this.dateOfBirth,
  });
}
```

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
| `Event` class | `@StateAction()` methods |
| `State` class | Same `@StateModel()` |
| `Bloc` class | `Feature<S>` class with `@DragonflyStateManager()` |
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
