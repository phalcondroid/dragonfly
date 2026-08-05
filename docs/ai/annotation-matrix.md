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
| `@EventModel(...)` | sealed class | `EventModelGenerator` | `.event.dart` part, same shape as `@StateModel` |
| `@Repository(...)` | abstract class w/ factory ctor | `RepositoryGenerator`, `InjectableVisitor` | `.repository.dart` part: `_ClassName` impl + lazy-singleton DI registration |
| `@Get/@Post/@Put/@Patch/@Delete` | repository method | `MedatadaExtractor.getMethodType`, `RepositoryGenerator` | HTTP verb and path segment in the generated call |
| `@Subscribe(channel:)` | repository method returning `Stream<T>` | `RepositoryVisitor`, `RepositoryGenerator.buildSubscriptionMethod` | A method resolving a `DragonflyRealtimeAdapter` by connection name and mapping each payload through `fromJson`. `channel` defaults to the method name |
| `@DragonflyStateManager(...)` | class extending `StateManager<S>` | `DragonflyStateManagerGenerator`, `InjectableVisitor`, `RouterGenerator` | `.state_manager.dart` part: `_$NameMixin`, `NameProvider` widget, one builder widget per state variant, `BuildContext` extension; plus factory DI registration |
| `@StateAction(...)` | state manager method | `DragonflyStateManagerGenerator` | With `debounce`/`throttle`: an `actions` façade routing through `StateManager.scheduleAction`. Without: nothing (the annotation is decorative) |
| `@Computed()` | state manager getter | `DragonflyStateManagerGenerator` | **Parsed, then discarded.** See gap #4 |
| `@InitialState()` | state manager getter | `DragonflyStateManagerGenerator` | Fallback only, for inferring `S` when the supertype is unreadable |
| `@InjectableUseCase(...)` | use-case class | `InjectableVisitor` | Factory registration in `.config.dart` |
| `@Inject('name')` / `@Named('name')` | constructor parameter | `InjectableVisitor` | `gh.get<T>(instanceName: 'name')` in the generated wiring |
| `@DragonflyInjectableInit()` | top-level function | `InjectableConfigGenerator` | `.config.dart`: `extension DragonflyContainerConfigX on DragonflyContainer` with `configureDependencies()` |
| `@DragonflyRouterConfig()` | class | `RouterGenerator` | `.router.dart`: `$NameConfig` mixin with `routes`, `routeConfigs`, `namedRoutes`, `initialRoute`, ACL-aware `onGenerateRoute` |
| `@DragonflyScreen(...)` | widget class | `RouterGenerator` | A route entry, its access config, and (if `provider:` is set) a wrapping `<Feature>Provider` |
| `@FormSchema(...)` | plain class | `FormSchemaGenerator` | `.form.dart` part: `<Name>Field` enum, `<Name>FormState`, `<Name>FormController` mixin. **Currently produces non-compiling output — see gap #3** |
| `@FormField(...)` | form schema field | `FormSchemaGenerator` | Label/hint/keyboard metadata on the generated field |
| Form validators (`@Required`, `@Email`, `@MinLength`, …) | form schema field | `FormSchemaGenerator` | `Validators.*` entries in the generated validator map |
| `@DragonflyBloc(...)` | bloc class | `DragonflyBlocGenerator`, `InjectableVisitor` | `.bloc.dart` part + factory DI registration. Legacy — prefer `@DragonflyStateManager` |
| `@DragonflyBlocView(...)` | widget class | `DragonflyBlocViewGenerator` | `.blocview.dart` part. Legacy |

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
| `@SideEffect()` | Side effects work, but via the runtime `sideEffect(...)` call — the annotation is decorative |
| `@StateSlot(...)` | Never read |
| `@DragonflySessionConfig(...)` | Session config is passed to `DragonflySessionManager.init()` at runtime instead |
| `@PathParam(...)` / `@QueryParam(...)` | Route parameter extraction is not implemented |
| `@JsonKey` / `@JsonIgnore` | Superseded by `@Field(field:)` / `@Field(ignore:)` |
| `@DragonflyStateBuilder` | Exported from `dragonfly_view.dart`, never read |
| `@Where(...)` | `annotations/where.dart`, never read |

---

## Deprecated aliases — keep working, never emit

Declared in `dragonfly_annotations/lib/annotations/component/presentation/feature/dragonfly_feature.dart`
and `dragonfly/lib/framework/feature/state_manager.dart`.

| Deprecated | Use instead |
| ---------- | ----------- |
| `@DragonflyFeature()`, `@DragonflyView()` | `@DragonflyStateManager()` |
| `@ViewAction()`, `@FeatureAction()` | `@StateAction()` |
| `Feature<S>` | `StateManager<S>` |
| `FeatureProvider`, `FeatureBuilder`, `FeatureListener`, `FeatureConsumer`, `FeatureSelector`, `FeatureSideEffectListener` | Drop the `Feature` prefix for `StateManager` |
| `context.feature<T>()`, `context.maybeFeature<T>()` | `context.stateManager<T>()`, `context.maybeStateManager<T>()` |
| `pushFeatureRoute`, `pushFeatureNamed` | `pushStateManagerRoute`, `pushNamed` |

---

## Required `part` directives

`PartBuilder` outputs are `part of` the annotated file, so the source **must** declare the
part, and **must** import everything the generated code references (a part file cannot
have its own imports).

| Annotation | `part` directive | Source file must also import |
| ---------- | ---------------- | ----------------------------- |
| `@FactoryModel` | `part 'name.model.dart';` | `package:dragonfly/dragonfly.dart` |
| `@StateModel` | `part 'name.state.dart';` | `package:dragonfly_annotations/...` |
| `@EventModel` | `part 'name.event.dart';` | `package:dragonfly_annotations/...` |
| `@Repository` | `part 'name.repository.dart';` | `package:dragonfly/dragonfly.dart` (for `DragonflyContainer`, `DragonflyLogManager`, `DragonflyNetworkHttpAdapter`, `HttpMethods`) |
| `@DragonflyStateManager` | `part 'name.state_manager.dart';` | `package:dragonfly/dragonfly.dart` **and** `package:flutter/material.dart` (generated provider/builder widgets) |
| `@FormSchema` | `part 'name.form.dart';` | `package:dragonfly/dragonfly.dart` — **missing in `example/`, which is why forms don't compile** |

`@DragonflyInjectableInit` and `@DragonflyRouterConfig` are `LibraryBuilder`s: they emit a
standalone file that you `import`, not a `part`.

---

## Regenerating this table

```bash
cd dragonfly_builder
for a in Path Query Body Header Authenticated Singleton StateSlot SideEffect; do
  printf "%-18s %s\n" "$a" "$(grep -rowE "\b$a\b" lib/ | wc -l)"
done
```

A count of `0` means dead. Move the row between sections when that changes.
