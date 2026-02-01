/// Annotation for creating event models used in the presentation layer.
///
/// This annotation generates sealed event classes typically used with BLoC pattern.
/// Each factory constructor in the annotated class becomes a subclass of the event.
///
/// Example usage:
/// ```dart
/// @EventModel()
/// sealed class UserEvent with _$UserEvent {
///   const factory UserEvent.loading() = UserEventLoading;
///   const factory UserEvent.getUser(User user) = UserEventGetUser;
///   const factory UserEvent.deleteUser(User user, Purchases purchases) = UserEventDeleteUser;
/// }
/// ```
///
/// The generator will create:
/// - A mixin with when/maybeWhen/map/maybeMap methods
/// - Sealed subclasses for each factory constructor
/// - Optional copyWith, equals, and toString methods
class EventModel {
  /// Whether to generate a copyWith method for each event variant.
  final bool copyWith;

  /// Whether to generate equality operators (== and hashCode).
  final bool equals;

  /// Whether to generate a toString method.
  final bool toStringMethod;

  /// Whether to generate when/maybeWhen pattern matching methods.
  final bool whenMethods;

  /// Whether to generate map/maybeMap pattern matching methods.
  final bool mapMethods;

  /// Creates an EventModel annotation.
  ///
  /// All options default to `true`.
  const EventModel({
    this.copyWith = true,
    this.equals = true,
    this.toStringMethod = true,
    this.whenMethods = true,
    this.mapMethods = true,
  });
}
