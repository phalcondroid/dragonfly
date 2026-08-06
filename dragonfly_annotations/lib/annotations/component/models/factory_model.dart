/// Annotation for creating factory models used in repository layer.
///
/// This annotation generates a model class with optional serialization,
/// equality, and string representation methods.
///
/// Example usage:
/// ```dart
/// @FactoryModel()
/// abstract interface class User implements _$UserContract {
///   factory User({required String name, required int age}) = _$User;
///   factory User.fromJson(Map<String, Object?> json) = _$User.fromJson;
/// }
/// ```
///
/// For generic models:
/// ```dart
/// @FactoryModel(generic: true)
/// abstract interface class `ServiceResponse<T>` implements `_$ServiceResponseContract<T>` {
///   factory ServiceResponse({required T data}) = _$ServiceResponse;
///   factory ServiceResponse.fromJson(
///     Map<String, Object?> json,
///     T Function(Object? json) fromJsonT,
///   ) = _$ServiceResponse.fromJson;
/// }
/// ```
class FactoryModel {
  /// Whether to generate a copyWith method.
  final bool copyWith;

  /// Whether the model uses generic type parameters.
  final bool generic;

  /// Whether the model represents a list type.
  final bool isList;

  /// Whether to generate a toJson method that converts to Map<String, dynamic>.
  final bool toJson;

  /// Whether to generate a toMap method that converts to Map<String, Object?>.
  final bool toMap;

  /// Whether to generate equality operators (== and hashCode).
  final bool equals;

  /// Whether to generate a toString method.
  final bool toStringMethod;

  /// Creates a FactoryModel annotation.
  ///
  /// All options default to `true` except for [generic], [isList], and [copyWith]
  /// which default to `false`.
  const FactoryModel({
    this.copyWith = false,
    this.generic = false,
    this.isList = false,
    this.toJson = true,
    this.toMap = true,
    this.equals = true,
    this.toStringMethod = true,
  });
}
