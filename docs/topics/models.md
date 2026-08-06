# Models

`@FactoryModel` and related annotations for defining data models with automatic
serialization, equality, and code generation.

`@FactoryModel` generates `fromJson`, optional `toJson`/`toMap`, `==`/`hashCode`,
`toString`, `copyWith`, and a contract interface. The `import` of
`package:dragonfly/dragonfly.dart` is mandatory — the generated part references
framework types and a part file cannot have its own imports.

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'character.model.dart';

@FactoryModel(toJson: true, equals: true, toStringMethod: true, copyWith: true)
abstract interface class Character implements _$CharacterContract {
  factory Character({
    @Field(field: 'id')   required int id,
    required String name,
    required String status,
    required String species,
    required String image,
  }) = _$Character;

  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
```

| `@FactoryModel` option | Default | Effect |
|------------------------|---------|--------|
| `toJson`               | `true`  | Generate `Map<String, Object?> toJson()` |
| `toMap`                | `true`  | Generate `Map<String, Object?> toMap()` |
| `equals`               | `true`  | Generate `==` and `hashCode` |
| `toStringMethod`       | `true`  | Generate `toString()` |
| `copyWith`             | `false` | Generate a `copyWith` method |

`@Field(field: 'json_key')` renames the serialised key. `@Field(convertTo: 'type')`
wires a type converter. `@Field(ignore: true)` omits the field.

### DDD aggregates

`@Aggregate` on a `@FactoryModel` marks it as an aggregate root with a unique
identity. The generated class implements `AggregateRoot<T>` and gains identity-based
equality, `sameIdentityAs`, and an `isNew` getter — two entities with the same
identity are the same entity regardless of other state changes.

```dart
@FactoryModel(toJson: true)
@Aggregate(identityField: 'id')
abstract interface class Character implements _$CharacterContract {
  factory Character({
    required int id, required String name, required String status,
  }) = _$Character;
  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
```

Generated: `class _$Character implements FactoryModelWatcher, Character, AggregateRoot<int>`
with `int get identity => id`, `bool get isNew => id == null`,
`bool sameIdentityAs(Object other) => other is Character && id == other.id`, and
identity-based `==`/`hashCode`.

`@ValueObject()` marks a model as immutable and compared by all fields (no identity).
`@DomainEvent()` is a marker annotation for event records implementing
`DomainEvent`.

---

[Back to README.md](../../README.md)
