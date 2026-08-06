# Annotations & Generated Files Reference

Reference tables for all framework annotations and the files they produce.

## Annotations reference

### Models & data

| Annotation | What it does |
|-----------|-------------|
| `@FactoryModel(...)` | Generates fromJson, optional toJson/toMap/equals/copyWith |
| `@Field(field:, value:, convertTo:, ignore:)` | Customises a model property's serialisation |
| `@Aggregate(identityField:)` | Marks an aggregate root — identity-based equality, `sameIdentityAs`, `isNew`, `AggregateRoot<T>` |
| `@ValueObject()` | Marks an immutable value object |
| `@DomainEvent()` | Marks a domain event record |
| `@StateModel()` | Generates a sealed state with when/maybeWhen and variant classes |

### Repositories

| Annotation | What it does |
|-----------|-------------|
| `@Repository(url:, connection:, realtimeConnection:)` | Generates the HTTP/realtime repository impl |
| `@Get/@Post/@Put/@Patch/@Delete` | HTTP verb + optional path/headers |
| `@Path('name')` | URL placeholder → `${name}` substitution |
| `@Query('name')` | Query-parameter binding |
| `@Body()` | Request body — serialises a model via `toJson` |
| `@Header(item:)` | Static header map merged into the request |
| `@Subscribe(channel:)` | WebSocket subscription — method returns `Stream<T>` |
| `@Authenticated()` | Routes through the session-aware adapter |

### State management

| Annotation | What it does |
|-----------|-------------|
| `@StateManager()` / `@StateManager(state: X)` | Declares a state manager (easy / StateModel mode) |
| `@Event(debounce:, throttle:)` | State-emitting method — auto loading/error dispatching |
| `@StateView(Manager)` | Binds a widget to a state manager — generates the flattening mixin |

### DI & configuration

| Annotation | What it does |
|-----------|-------------|
| `@UseCase(instanceName:, env:, scope:, order:)` | DI registration for a use-case class |
| `@InjectableInit()` | Marks the DI init function — triggers `.config.dart` generation |
| `@Injectable(as:, env:, instanceName:)` | Registers a class as a factory |
| `@Singleton(as:, env:, instanceName:, signalsReady:, dependsOn:, dispose:)` | Registers as eager singleton |
| `@LazySingleton(as:, env:, instanceName:, dispose:)` | Registers as lazy singleton |
| `@Inject('name')` / `@Named('name')` | Named dependency on a constructor parameter |

### Routing

| Annotation | What it does |
|-----------|-------------|
| `@RouterConfig()` | Triggers router code generation |
| `@Screen(path:, name:, initial:, access:, roles:, permissions:)` | Registers a screen route with ACL |
| `@PathParam('name')` / `@QueryParam('name')` | Extracts a route/query parameter in a screen constructor |
| `@ScreenTransition` | Enum: `fade`, `slideRight`, `slideUp`, `scale`, `none`, `platform` |
| `@SessionConfig(...)` | Declarative session configuration |

### Forms

| Annotation | What it does |
|-----------|-------------|
| `@FormSchema(validateOnChange:, validateOnBlur:)` | Generates form state class + field enum |
| `@FormField(label:, hint:, keyboardType:, obscureText:)` | Field metadata for UI builders |
| `@Required/@Email/@MinLength/@MaxLength` | String validators |
| `@Pattern/@Url/@Phone/@Alphanumeric/@Alpha/@Numeric` | String format validators |
| `@Min/@Max/@Range/@Positive/@Negative` | Numeric validators |
| `@EqualTo/@NotEqualTo` | Comparison validators |
| `@PastDate/@FutureDate/@MinAge` | Date validators |
| `@MinItems/@MaxItems` | Collection validators |
| `@MustBeTrue/@MustBeFalse` | Boolean validators |
| `@CreditCard/@Cvv/@ExpiryDate` | Payment validators |
| `@StrongPassword` | Password strength validator |
| `@RequiredIf/@RequiredUnless` | Conditional validators |
| `@Custom` | Custom validation function |

## Generated files

| Extension | Input annotation | Content |
|-----------|-----------------|---------|
| `.model.dart` | `@FactoryModel` | Model impl, fromJson, toJson, equals, copyWith |
| `.state.dart` | `@StateModel` | Sealed state class, variants, when/maybeWhen |
| `.repository.dart` | `@Repository` | HTTP/realtime repository impl |
| `.state_manager.dart` | `@StateManager` | `$XController` + (easy mode) generated state class |
| `.view.dart` | `@StateView` | `$Manager` flattening mixin |
| `.form.dart` | `@FormSchema` | Form state class, field enum, validators |
| `.config.dart` | `@InjectableInit` | DI registration extension |
| `.router.dart` | `@RouterConfig` | Routes map, ACL config, onGenerateRoute |
| `.dragonfly.dart` | (component barrel) | Re-exports all generated sources in the component |

All generated files carry `// GENERATED CODE - DO NOT MODIFY BY HAND` and should
never be edited. Change the annotated source and rebuild.

[Back to README](../../README.md)
