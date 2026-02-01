/// Annotation for customizing field mapping in factory models.
///
/// Use this annotation on constructor parameters to customize
/// how the field is serialized/deserialized.
///
/// Example usage:
/// ```dart
/// @FactoryModel()
/// abstract interface class User implements _$UserContract {
///   factory User({
///     @Field(field: 'user_id') required int id,
///     @Field(value: 'Unknown') String? name,
///     @Field(field: 'created_at', convertTo: 'DateTime') required String createdAt,
///   }) = _$User;
/// }
/// ```
class Field {
  /// The JSON field name to use for serialization/deserialization.
  ///
  /// If not specified, the parameter name is used.
  final String? field;

  /// The type to convert the field to during deserialization.
  ///
  /// This is useful for converting string dates to DateTime, etc.
  final String? convertTo;

  /// The default value to use if the field is null or missing.
  final Object? value;

  /// Whether this field should be ignored during serialization.
  final bool ignore;

  /// Whether this field should be included in the fromJson constructor.
  final bool fromJson;

  /// Whether this field should be included in the toJson method.
  final bool toJson;

  /// Creates a Field annotation.
  const Field({
    this.field,
    this.convertTo,
    this.value,
    this.ignore = false,
    this.fromJson = true,
    this.toJson = true,
  });
}

/// Annotation to mark a field as ignored during serialization/deserialization.
class JsonIgnore {
  const JsonIgnore();
}

/// Annotation to provide a custom key for JSON serialization.
class JsonKey {
  /// The JSON key name.
  final String name;

  /// Default value if null.
  final Object? defaultValue;

  /// Whether to include if null.
  final bool includeIfNull;

  const JsonKey({
    required this.name,
    this.defaultValue,
    this.includeIfNull = true,
  });
}
