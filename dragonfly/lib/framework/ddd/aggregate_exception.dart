/// Thrown when an aggregate invariant is violated — for example, attempting to
/// persist an entity with a missing identity field or violating a business rule
/// enforced by the aggregate root.
class AggregateException implements Exception {
  final String message;

  const AggregateException(this.message);

  @override
  String toString() => 'AggregateException: $message';
}
