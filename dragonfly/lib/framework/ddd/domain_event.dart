/// Marker interface for domain-event classes.
///
/// A domain event is an immutable record of something that happened in an
/// aggregate. Event classes annotated with `@DomainEvent()` implement this
/// automatically through generation.
abstract interface class DomainEvent {
  /// When the event occurred.
  DateTime get occurredOn;
}
