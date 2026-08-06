# ADR 0007 — DDD aggregates in the data layer

**Date:** 2026-08-05
**Status:** Accepted
**Deciders:** Architecture extension — placing domain logic responsibility into entity
models through aggregates, value objects, and repositories.

## Context

The data layer (`@FactoryModel`, `@Repository`, `@UseCase`) lacked DDD semantics.
Models were pure data carriers with generated serialisation — they had no concept of
identity, no invariant enforcement, and no aggregate boundaries. Repositories generated
generic HTTP calls; there was no aggregate-specific loading or saving. Use cases
orchestrated raw data transforms with no domain language.

The framework's goal — app authors write only use cases and UI — requires the data
layer to carry domain responsibility natively.

## Decision

Introduce three annotations and supporting runtime types that bring DDD aggregates
into the existing `@FactoryModel` + `@Repository` + `@UseCase` pipeline:

### `@AggregateRoot`

Placed on a `@FactoryModel` class. Declares the model as an aggregate root with a
unique identity field and optional optimistic-locking version tracking.

```dart
@FactoryModel(toJson: true, equals: true)
@AggregateRoot(identityField: 'id')
abstract interface class Character implements _$CharacterContract {
  factory Character({
    required int id,
    required String name,
    required String status,
  }) = _$Character;

  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
```

The generator produces:
- **Identity-based equality** — `==` and `hashCode` use only the `identityField`
  (a model with `@AggregateRoot` never compares by value; identity is the contract)
- **`sameIdentityAs(Character other)`** — identity comparison helper
- **`isNew` getter** — `true` when the identity field is `null` (unsaved entity)
- **Repository contract** — a generated interface `CharacterRepositoryContract`
  with typed `findById`, `save`, and `delete` methods that the `@Repository`
  implementation fulfills

### `@ValueObject`

Placed on a `@FactoryModel` class (or standalone). Marks the class as a value object
within an aggregate boundary — immutable, compared by all fields, no identity.

```dart
@FactoryModel(toJson: true)
@ValueObject()
abstract interface class Money implements _$MoneyContract {
  factory Money({required double amount, required String currency}) = _$Money;
}
```

The generator:
- Ensures all fields are `final`
- Generates full value equality (all fields)
- `copyWith` returns a new instance (immutability)
- Validates that the class is not also annotated `@AggregateRoot`

### Repository integration

When a `@Repository` abstract class references an `@AggregateRoot` in its methods,
the generated implementation includes:

```dart
@Repository(url: "character")
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  // Generated from @AggregateRoot contract:
  Future<Character?> findById(int id);
  Future<Character> save(Character character);
  Future<void> delete(int id);

  // Custom methods still work:
  @Get()
  Future<ServiceResponse<Character>> getAll(@Query('name') String name);
}
```

`save` automatically chooses `POST` or `PUT` based on `isNew` (POST for new entities,
PUT for updates). `delete` sends a `DELETE` to `{url}/{id}`. `findById` sends a `GET`
to `{url}/{id}`.

### Runtime types (`framework/ddd/`)

| Type | Purpose |
|------|---------|
| `AggregateRoot<T>` | Contract interface — requires identity field, marks root |
| `AggregateRepository<T>` | Base repository contract with `findById`/`save`/`delete` |
| `DomainEvent` | Marker interface for domain event classes |
| `AggregateException` | Thrown on invariant violations |

## Consequences

- Data models now carry domain semantics — identity vs value comparison is a
  framework-level decision, not a hand-written convention
- Repository generation is richer: aggregate lifecycle methods are typed and
  inferred from the model's annotations, reducing boilerplate
- The layering stays intact: screen → state manager → use case → repository
  (aggregate) → network — the aggregate semantics live in the data layer,
  surfaced through the repository contract

## References

- `dragonfly_annotations/lib/annotations/component/models/aggregate.dart`
- `dragonfly/lib/framework/ddd/aggregate_root.dart`
- `dragonfly/lib/framework/ddd/aggregate_repository.dart`
- `dragonfly_builder/lib/builder/generators/aggregate_generator.dart`
