# Annotation → generator → output matrix

Lookup table for every annotation exported by `dragonfly_annotations`. The **Consumed by**
column is the ground truth: it was produced by grepping `dragonfly_builder/lib/` for each
annotation name. An annotation with no consumer has **no effect at runtime or build time**,
no matter what `README.md` says.

---

## Live annotations

| Annotation | Applied to | Consumed by | Produces |
| ---------- | ---------- | ----------- | -------- |
| `@FactoryModel(...)` | abstract interface class | `FactoryModelGenerator`, `FactoryModelRegistry` | `.model.dart` part: `_$Name` impl, `_$NameContract`, `fromJson`, and optionally `toJson`/`toMap`/`==`/`hashCode`/`toString`/`copyWith` |
| `@Field(...)` | model constructor param | `FactoryModelVisitor` | JSON key rename, default value, converter, include/exclude |
| `@StateModel(...)` | sealed class | `StateModelGenerator`, `SealedClassVisitor` | `.state.dart` part: one class per `factory` variant + `when`/`maybeWhen`/`map`/`maybeMap` |
| `@Repository(...)` | abstract class w/ factory ctor | `RepositoryGenerator`, `InjectableVisitor` | `.repository.dart` part: `_ClassName` impl + lazy-singleton DI registration |
| `@Get/@Post/@Put/@Patch/@Delete` | repository method | `MedatadaExtractor.getMethodType`, `RepositoryGenerator` | HTTP verb and path segment in the generated call |
| `@Subscribe(channel:)` | repository method returning `Stream<T>` | `RepositoryVisitor`, `RepositoryGenerator.buildSubscriptionMethod` | A method resolving a `DragonflyRealtimeAdapter` by connection name and mapping each payload through `fromJson`. `channel` defaults to the method name |
| `@StateManager(...)` | plain class | `StateManagerGenerator`, `ViewGenerator` (indirectly), `InjectableVisitor` | `.state_manager.dart` part: `$NameController extends DragonflyController` + (easy mode) the `NameState` sealed class; plus factory DI registration for the delegate and a lazy-singleton registration (with `dispose`) for the controller |
| `@StateManager(state: XState)` | plain class | same | StateModel mode: no state class generated; `@Event` methods must return `XState`; `XState` must declare zero-arg `initial`, and conventionally `loading` / `error({required String message})` |
| `@Event(debounce:, throttle:)` | `@StateManager` method | `StateManagerDescriber` (shared), `StateManagerGenerator`, `ViewGenerator` | A controller dispatcher that emits `loading`, invokes the method, emits the result variant (or `error`); `debounce`/`throttle` route through `DragonflyController.schedule`. The method name becomes the variant name, its return type the payload |
| `@StateView(Manager)` | widget class | `ViewGenerator` | `.view.dart` part: `$Manager` mixin flattening dispatchers, `when`, typed `build<Event>` builders and `buildFor` onto the widget. One mixin per unique manager per file |
| `@UseCase(...)` | use-case class | `InjectableVisitor` | Factory registration in `.config.dart` |
| `@Inject('name')` / `@Named('name')` | constructor parameter | `InjectableVisitor` | `gh.get<T>(instanceName: 'name')` in the generated wiring |
| `@InjectableInit()` | top-level function | `InjectableConfigGenerator` | `.config.dart`: `extension DragonflyContainerConfigX on DragonflyContainer` with `configureDependencies()` |
| `@RouterConfig()` | class | `RouterGenerator` | `.router.dart`: `$NameConfig` mixin with `routes`, `routeConfigs`, `namedRoutes`, `initialRoute`, ACL-aware `onGenerateRoute` |
| `@Screen(...)` | widget class | `RouterGenerator` | A route entry and its access config. No provider wrapping — controllers resolve from DI inside the view mixin |
| `@FormSchema(...)` | plain class | `FormSchemaGenerator` | `.form.dart` part: `<Name>Field` enum, `<Name>FormState`, `<Name>FormController` mixin (`on DragonflyController<S>`). **Currently produces non-compiling output — see gap #3** |
| `@FormField(...)` | form schema field | `FormSchemaGenerator` | Label/hint/keyboard metadata on the generated field |
| Form validators (`@Required`, `@Email`, `@MinLength`, …) | form schema field | `FormSchemaGenerator` | `Validators.*` entries in the generated validator map |

---

## Dead annotations — exported but never consumed

Every one of these has **zero** references in `dragonfly_builder/lib/`. Applying them is a
no-op. Do not suggest them to users, and do not "use" them in examples.

| Annotation | Notes |
| ---------- | ----- |
| `@Path(...)` | Parameter binding is unimplemented — gap #2 |
| `@Query(...)` | Parameter binding is unimplemented — gap #2 |
| `@Body()` | Request bodies are never sent |
| `@Header(...)` | Method-level `@Get(headers:)` is parsed then dropped; `@Header` is not read at all |
| `@Authenticated(...)` | No generator emits token injection |
| `@Singleton()` | `InjectableVisitor` does not check for it |
| `@LazySingleton()` | Same |
| `@Injectable()` | Same |
| `@SessionConfig(...)` | Session config is passed to `DragonflySessionManager.init()` at runtime instead |
| `@PathParam(...)` / `@QueryParam(...)` | Route parameter extraction is not implemented |
| `@JsonKey` / `@JsonIgnore` | Superseded by `@Field(field:)` / `@Field(ignore:)` |
| `@Where(...)` | `annotations/where.dart`, never read |

---

## Deleted in the v2 clean break — do not reintroduce

| Deleted | Replacement |
| ------- | ----------- |
| `@DragonflyStateManager`, `@DragonflyFeature`, `@DragonflyView` | `@StateManager(...)` on a plain class |
| `@StateAction`, `@ViewAction`, `@FeatureAction` | `@Event()` (return values; no hand-written `emit`) |
| `@InitialState` | The state's zero-arg `initial` factory / built-in easy-mode variant |
| `@SideEffect`, `@Computed`, `@StateSlot` | Nothing (no v2 equivalent yet) |
| `@EventModel` | `@Event` methods on a `@StateManager` |
| `@DragonflyBloc`, `@DragonflyBlocView`, `@DragonflyStateBuilder`, `class Bloc` | `@StateManager` + `@StateView` |
| `StateManager<S>`, `Feature<S>` base classes | `DragonflyController<S>` (only subclassed by generated code) |
| `StateManagerProvider`/`StateManagerBuilder`/`StateScope`/`StateView`/`StateSelector` | `DragonflyStateBuilder` + the `$Manager` view mixin |
| `DefaultSideEffectHandler`, `ScreenProvider`, `DragonflyScreenBase` | Nothing (no v2 equivalent) |
| `UseCase` contract interfaces | The `@UseCase` annotation (name reuse — the contract conflicted with it) |
| `@DragonflyScreen(provider:)` param | Gone — the view mixin resolves the controller from DI |

---

## Deprecated aliases — keep working, never emit

Declared in `dragonfly_annotations` (`injectable_annotations.dart`,
`session_annotations.dart`, `router_config.dart`).

| Deprecated | Use instead |
| ---------- | ----------- |
| `@InjectableUseCase()` | `@UseCase()` |
| `@DragonflyInjectableInit()` | `@InjectableInit()` |
| `@DragonflyScreen()` | `@Screen()` |
| `@DragonflySessionConfig()` | `@SessionConfig()` |
| `@DragonflyRouterConfig()` | `@RouterConfig()` |

---

## Required `part` directives

`PartBuilder` outputs are `part of` the annotated file, so the source **must** declare the
part, and **must** import everything the generated code references (a part file cannot
have its own imports).

| Annotation | `part` directive | Source file must also import |
| ---------- | ---------------- | ----------------------------- |
| `@FactoryModel` | `part 'name.model.dart';` | `package:dragonfly/dragonfly.dart` |
| `@StateModel` | `part 'name.state.dart';` | `package:dragonfly_annotations/...` |
| `@Repository` | `part 'name.repository.dart';` | `package:dragonfly/dragonfly.dart` (for `DragonflyContainer`, `DragonflyLogManager`, `DragonflyNetworkHttpAdapter`, `HttpMethods`) |
| `@StateManager` | `part 'name.state_manager.dart';` | `package:dragonfly/dragonfly.dart` (for `DragonflyController`); StateModel mode: the state model file |
| `@StateView` | `part 'name.view.dart';` | Flutter widgets, `package:dragonfly/dragonfly.dart` (for `DragonflyStateBuilder`, `DragonflyContainer`), the state manager file, and (StateModel mode) the state model file |
| `@FormSchema` | `part 'name.form.dart';` | `package:dragonfly/dragonfly.dart` — **missing in `example/`, which is why forms don't compile** |

`@InjectableInit` and `@RouterConfig` are `LibraryBuilder`s: they emit a standalone file
that you `import`, not a `part`.

---

## Regenerating this table

```bash
cd dragonfly_builder
for a in Path Query Body Header Authenticated Singleton; do
  printf "%-18s %s\n" "$a" "$(grep -rowE "\b$a\b" lib/ | wc -l)"
done
```

A count of `0` means dead. Move the row between sections when that changes.
