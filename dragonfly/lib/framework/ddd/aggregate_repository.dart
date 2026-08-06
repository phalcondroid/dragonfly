/// Base repository contract for aggregate-root persistence.
///
/// Generated `@Repository` classes that reference an `@AggregateRoot` model
/// automatically inherit these methods. The implementations dispatch to the
/// appropriate HTTP verbs:
///
/// - [findById] → `GET {url}/{id}`
/// - [save] → `POST {url}` when `isNew`, `PUT {url}/{id}` otherwise
/// - [delete] → `DELETE {url}/{id}`
abstract interface class AggregateRepository<T> {
  /// Finds an aggregate by its identity. Returns `null` when absent.
  Future<T?> findById(Object id);

  /// Persists the aggregate. Uses `POST` for new entities and `PUT` for
  /// updates (derived from `AggregateRoot.isNew`).
  Future<T> save(T aggregate);

  /// Deletes the aggregate with the given identity.
  Future<void> delete(Object id);
}
