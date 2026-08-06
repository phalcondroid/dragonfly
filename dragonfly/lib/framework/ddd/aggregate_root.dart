/// Contract interface for an aggregate root.
///
/// Generated `@AggregateRoot` models implement this automatically — you never
/// write the implementation by hand. The contract exposes:
///
/// - [identity] — the unique identifier (the field named by
///   `@AggregateRoot(identityField:)`)
/// - [isNew] — `true` before the entity is persisted (identity is null)
/// - [sameIdentityAs] — identity-based comparison (ignores other fields)
///
/// Repositories use this contract to generate typed `findById`/`save`/`delete`
/// methods for every aggregate root.
abstract interface class AggregateRoot<T> {
  /// The entity's unique identity.
  T get identity;

  /// Whether the entity has not yet been persisted (identity is null).
  bool get isNew;

  /// Returns `true` when [other] has the same [identity] as `this`,
  /// regardless of other field values.
  bool sameIdentityAs(Object other);
}
