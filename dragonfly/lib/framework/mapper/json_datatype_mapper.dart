import 'package:dragonfly/framework/contracts/models/factory_model_watcher.dart';

/// Enum representing different data types for JSON mapping.
enum DataTypeEnum {
  isClass,
  isObject,
  isString,
  isDouble,
  isInt,
  isBool,
  isList,
  isMap,
  isSet,
  isNull,
  isDateTime,
  isDynamic,
}

/// A utility class for mapping JSON data to Dart types with type safety.
///
/// This class provides methods to safely extract and convert values from
/// JSON maps (Map<String, Object?>) to strongly typed Dart objects.
class JsonDatatypeMapper {
  /// Maps a value from a JSON map to a generic type [T].
  ///
  /// [json] - The source JSON map.
  /// [jsonKey] - The key to extract from the map.
  /// [defaultValue] - Optional default value if the key is missing or null.
  /// [mustWithDefault] - If true, throws an exception if defaultValue is null
  ///                     and the key is missing.
  ///
  /// Returns the value cast to type [T], or [defaultValue] if the key is missing.
  ///
  /// Throws [JsonMappingException] if:
  /// - The key is missing and [T] is not nullable and no default is provided.
  /// - The value cannot be cast to type [T].
  static T mapForGeneric<T>(
    Map<String, Object?> json,
    String jsonKey, {
    T? defaultValue,
    bool mustWithDefault = false,
  }) {
    final typeString = T.toString();
    final bool isNullable = typeString.endsWith('?');

    try {
      final value = json[jsonKey];

      // Handle null values
      if (value == null) {
        if (isNullable) {
          return null as T;
        }
        if (defaultValue != null) {
          return defaultValue;
        }
        if (mustWithDefault) {
          throw JsonMappingException(
            'Required default value missing for key "$jsonKey" of type $T',
          );
        }
        throw JsonMappingException(
          'Null value for non-nullable key "$jsonKey" of type $T',
        );
      }

      // Handle DateTime conversion
      if (_isDateTimeType(typeString)) {
        return _parseDateTime(value, jsonKey, isNullable) as T;
      }

      // Handle primitive types with proper conversion
      if (value is T) {
        return value as T;
      }

      // Try to convert numeric types
      if (_isNumericType(typeString)) {
        final converted = _convertNumeric<T>(value, typeString);
        if (converted != null) {
          return converted;
        }
      }

      // Try direct cast
      return value as T;
    } catch (e) {
      if (e is JsonMappingException) {
        rethrow;
      }

      // Return default or null for nullable types on error
      if (defaultValue != null) {
        return defaultValue as T;
      }
      if (isNullable) {
        return null as T;
      }

      throw JsonMappingException(
        'Failed to map "$jsonKey" to type $T: $e',
      );
    }
  }

  /// Maps a value from a JSON map for a generic type parameter.
  ///
  /// Use this method when deserializing generic models where the type
  /// is a type parameter (e.g., T in ServiceResponse<T>).
  ///
  /// [json] - The source JSON map.
  /// [jsonKey] - The key to extract from the map.
  /// [fromJson] - A function to convert the raw JSON to the target type.
  static T mapForTypeParameter<T>(
    Map<String, Object?> json,
    String jsonKey,
    T Function(Object? json) fromJson,
  ) {
    final value = json[jsonKey];
    if (value == null) {
      final typeString = T.toString();
      if (typeString.endsWith('?')) {
        return null as T;
      }
      throw JsonMappingException(
        'Null value for non-nullable key "$jsonKey" of type $T',
      );
    }
    return fromJson(value);
  }

  /// Maps a JSON list to a typed List<T>.
  ///
  /// [value] - The source list (can be dynamic).
  /// [factoryFn] - A function to convert each item to type [T].
  ///
  /// Returns a List<T> with all items converted.
  static List<T> mapGenericList<T>(
    dynamic value,
    T Function(dynamic e) factoryFn,
  ) {
    if (value == null) {
      return <T>[];
    }

    if (value is! List) {
      throw JsonMappingException(
        'Expected List but got ${value.runtimeType}',
      );
    }

    return value.map((e) {
      if (e == null) {
        final typeString = T.toString();
        if (typeString.endsWith('?')) {
          return null as T;
        }
        throw JsonMappingException('Null item in list for non-nullable type $T');
      }

      // Handle primitive types directly
      if (_isPrimitiveType<T>()) {
        return e as T;
      }

      // Handle nested lists
      if (e is List && T.toString().startsWith('List')) {
        return e as T;
      }

      // Handle maps
      if (e is Map && T.toString().startsWith('Map')) {
        return e as T;
      }

      // Use factory function for complex types
      return factoryFn(e);
    }).toList();
  }

  /// Maps a JSON list for a generic type parameter.
  ///
  /// Use this for generic models like ServiceResponse<T> where the list
  /// item type is a type parameter.
  static List<T> mapGenericListForTypeParameter<T>(
    dynamic value,
    T Function(Object? json) fromJson,
  ) {
    if (value == null) {
      return <T>[];
    }

    if (value is! List) {
      throw JsonMappingException(
        'Expected List but got ${value.runtimeType}',
      );
    }

    return value.map((e) => fromJson(e)).toList();
  }

  /// Maps a JSON map to a typed Map<K, V>.
  ///
  /// [value] - The source map (can be dynamic).
  /// [keyFromJson] - A function to convert each key to type [K].
  /// [valueFromJson] - A function to convert each value to type [V].
  static Map<K, V> mapGenericMap<K, V>(
    dynamic value,
    K Function(dynamic key) keyFromJson,
    V Function(dynamic value) valueFromJson,
  ) {
    if (value == null) {
      return <K, V>{};
    }

    if (value is! Map) {
      throw JsonMappingException(
        'Expected Map but got ${value.runtimeType}',
      );
    }

    return value.map((k, v) => MapEntry(keyFromJson(k), valueFromJson(v)));
  }

  /// Maps a nullable value from a JSON map.
  ///
  /// This is a convenience method for nullable types that handles null gracefully.
  static T? mapNullable<T>(
    Map<String, Object?> json,
    String jsonKey,
    T Function(Object? value) fromJson,
  ) {
    final value = json[jsonKey];
    if (value == null) {
      return null;
    }
    return fromJson(value);
  }

  /// Maps a nested object from a JSON map.
  ///
  /// [json] - The source JSON map.
  /// [jsonKey] - The key to extract from the map.
  /// [fromJson] - A function to convert the nested map to type [T].
  static T mapNestedObject<T>(
    Map<String, Object?> json,
    String jsonKey,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    final value = json[jsonKey];
    if (value == null) {
      final typeString = T.toString();
      if (typeString.endsWith('?')) {
        return null as T;
      }
      throw JsonMappingException(
        'Null value for non-nullable nested object "$jsonKey" of type $T',
      );
    }

    if (value is! Map<String, Object?>) {
      // Try to cast from Map<String, dynamic>
      if (value is Map) {
        return fromJson(Map<String, Object?>.from(value));
      }
      throw JsonMappingException(
        'Expected Map for key "$jsonKey" but got ${value.runtimeType}',
      );
    }

    return fromJson(value);
  }

  /// Maps a nullable nested object from a JSON map.
  static T? mapNullableNestedObject<T>(
    Map<String, Object?> json,
    String jsonKey,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    final value = json[jsonKey];
    if (value == null) {
      return null;
    }

    if (value is! Map) {
      throw JsonMappingException(
        'Expected Map for key "$jsonKey" but got ${value.runtimeType}',
      );
    }

    return fromJson(Map<String, Object?>.from(value));
  }

  // Helper methods

  static bool _isPrimitiveType<T>() {
    final typeString = T.toString().replaceAll('?', '');
    return typeString == 'String' ||
        typeString == 'int' ||
        typeString == 'double' ||
        typeString == 'num' ||
        typeString == 'bool' ||
        typeString == 'dynamic' ||
        typeString == 'Object';
  }

  static bool _isDateTimeType(String typeString) {
    final cleanType = typeString.replaceAll('?', '');
    return cleanType == 'DateTime';
  }

  static bool _isNumericType(String typeString) {
    final cleanType = typeString.replaceAll('?', '');
    return cleanType == 'int' || cleanType == 'double' || cleanType == 'num';
  }

  static T? _convertNumeric<T>(Object value, String typeString) {
    final cleanType = typeString.replaceAll('?', '');

    if (value is num) {
      if (cleanType == 'int') {
        return value.toInt() as T;
      }
      if (cleanType == 'double') {
        return value.toDouble() as T;
      }
      if (cleanType == 'num') {
        return value as T;
      }
    }

    if (value is String) {
      if (cleanType == 'int') {
        return int.tryParse(value) as T?;
      }
      if (cleanType == 'double') {
        return double.tryParse(value) as T?;
      }
    }

    return null;
  }

  static DateTime? _parseDateTime(
    Object value,
    String jsonKey,
    bool isNullable,
  ) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }

      // Try parsing as milliseconds since epoch
      final millis = int.tryParse(value);
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (isNullable) {
      return null;
    }

    throw JsonMappingException(
      'Cannot parse DateTime from value "$value" for key "$jsonKey"',
    );
  }

  /// Gets the data type enum for a given value.
  static DataTypeEnum getDataType(Object? value) {
    if (value == null) return DataTypeEnum.isNull;
    if (value is String) return DataTypeEnum.isString;
    if (value is int) return DataTypeEnum.isInt;
    if (value is double) return DataTypeEnum.isDouble;
    if (value is bool) return DataTypeEnum.isBool;
    if (value is List) return DataTypeEnum.isList;
    if (value is Map) return DataTypeEnum.isMap;
    if (value is Set) return DataTypeEnum.isSet;
    if (value is DateTime) return DataTypeEnum.isDateTime;
    if (value is FactoryModelWatcher) return DataTypeEnum.isClass;
    return DataTypeEnum.isObject;
  }
}

/// Exception thrown when JSON mapping fails.
class JsonMappingException implements Exception {
  final String message;

  const JsonMappingException(this.message);

  @override
  String toString() => 'JsonMappingException: $message';
}
