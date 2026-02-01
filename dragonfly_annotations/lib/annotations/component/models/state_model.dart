/// Annotation for creating state models used in the presentation layer.
///
/// This annotation generates sealed state classes typically used with BLoC pattern.
/// Each factory constructor in the annotated class becomes a subclass of the state.
///
/// Example usage:
/// ```dart
/// @StateModel()
/// sealed class UserState with _$UserState {
///   const factory UserState.initial() = UserStateInitial;
///   const factory UserState.loading() = UserStateLoading;
///   const factory UserState.loaded(User user) = UserStateLoaded;
///   const factory UserState.error(String message) = UserStateError;
/// }
/// ```
///
/// The generator will create:
/// - A mixin with when/maybeWhen/map/maybeMap methods
/// - Sealed subclasses for each factory constructor
/// - CopyWith methods for stateful variants
/// - Optional equality and toString methods
class StateModel {
  /// Whether to generate a copyWith method for each state variant.
  final bool copyWith;

  /// Whether to generate a toJson method.
  final bool toJson;

  /// Whether to generate a toMap method.
  final bool toMap;

  /// Whether to generate equality operators (== and hashCode).
  final bool equals;

  /// Whether to generate a toString method.
  final bool toStringMethod;

  /// Whether to generate when/maybeWhen pattern matching methods.
  final bool whenMethods;

  /// Whether to generate map/maybeMap pattern matching methods.
  final bool mapMethods;

  /// Creates a StateModel annotation.
  ///
  /// [copyWith], [equals], [toStringMethod], [whenMethods], and [mapMethods]
  /// default to `true`. [toJson] and [toMap] default to `false`.
  const StateModel({
    this.copyWith = true,
    this.toJson = false,
    this.toMap = false,
    this.equals = true,
    this.toStringMethod = true,
    this.whenMethods = true,
    this.mapMethods = true,
  });
}
