import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Declares a `@FactoryModel` class as the root of a DDD aggregate.
///
/// An aggregate root has a unique identity and is the entry point for all
/// operations on its cluster of entities and value objects. The generated code
/// produces:
///
/// - **Identity-based equality** — `==` / `hashCode` use only the identity
///   field, not all fields. Two aggregates with the same identity are the
///   same entity regardless of other state.
/// - **`sameIdentityAs(other)`** — convenience identity comparison.
/// - **`isNew`** — true when the identity field is null (not yet persisted).
/// - **A repository contract** — typed `findById` / `save` / `delete` methods
///   that the enclosing `@Repository` implementation fulfills.
///
/// ```dart
/// @FactoryModel(toJson: true)
/// @Aggregate(identityField: 'id')
/// abstract interface class Character implements _$CharacterContract {
///   factory Character({
///     required int id,
///     required String name,
///   }) = _$Character;
///
///   factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
/// }
/// ```
@immutable
@Target({TargetKind.classType})
class Aggregate {
  /// The field used as the entity's unique identity. Defaults to `'id'`.
  /// Equality, `sameIdentityAs`, and `isNew` are all derived from this field.
  final String identityField;

  /// When true, a `version` int field is expected on the model and `save` uses
  /// optimistic-locking (the version is sent and incremented on updates).
  final bool optimisticLocking;

  const Aggregate({
    this.identityField = 'id',
    this.optimisticLocking = false,
  });
}

/// Declares a class as a DDD value object — immutable, compared by all fields,
/// with no identity of its own.
///
/// Value objects live inside aggregate boundaries. They are interchangeable
/// when all fields are equal. The generator:
///
/// - Enforces that all fields are `final` (compilation error otherwise).
/// - Generates full value equality (all fields participate in `==` / `hashCode`).
/// - Ensures `copyWith` returns a new instance.
/// - Rejects co-placement with `@Aggregate` (a class cannot be both).
///
/// ```dart
/// @FactoryModel(toJson: true)
/// @ValueObject()
/// abstract interface class Money implements _$MoneyContract {
///   factory Money({required double amount, required String currency}) = _$Money;
/// }
/// ```
@immutable
@Target({TargetKind.classType})
class ValueObject {
  const ValueObject();
}

/// Marks a class as a domain event — a record of something that happened in an
/// aggregate. Domain events are immutable and typically carry the aggregate's
/// identity and a timestamp.
///
/// ```dart
/// @DomainEvent()
/// class CharacterCreated {
///   final int characterId;
///   final String name;
///   final DateTime occurredOn;
///
///   const CharacterCreated({
///     required this.characterId,
///     required this.name,
///   }) : occurredOn = DateTime.now();
/// }
/// ```
@immutable
@Target({TargetKind.classType})
class DomainEvent {
  const DomainEvent();
}
