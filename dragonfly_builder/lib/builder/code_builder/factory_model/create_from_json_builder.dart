import 'package:dragonfly_builder/builder/models/factory_model_field.dart';
import 'package:dragonfly_builder/builder/visitor/factory_model_visitor.dart';
import 'package:code_builder/code_builder.dart' as cb;

/// Builder for creating fromJson factory constructors.
class CreateFromJsonBuilder {
  /// Builds a fromJson factory constructor.
  ///
  /// For non-generic models:
  /// ```dart
  /// factory _$Model.fromJson(Map<String, Object?> json) {
  ///   return _$Model(...);
  /// }
  /// ```
  ///
  /// For generic models:
  /// ```dart
  /// factory _$Model.fromJson(
  ///   Map<String, Object?> json,
  ///   T Function(Object? json) fromJsonT,
  /// ) {
  ///   return _$Model(...);
  /// }
  /// ```
  cb.Constructor fromJsonBuilder(
    FactoryModelVisitor visitor,
    List<FactoryModelField> properties,
    bool isGeneric,
  ) {
    // Get generic type names from the visitor
    final genericTypeNames = _extractGenericTypeNames(visitor);

    final constructorArgs = properties.map((property) {
      return '${property.name}: ${_buildFieldMapping(property, isGeneric, genericTypeNames)}';
    }).join(', ');

    final body = 'return _\$${visitor.className}($constructorArgs);';

    return cb.Constructor((c) {
      c
        ..factory = true
        ..name = 'fromJson'
        ..requiredParameters.add(cb.Parameter((p) => p
          ..name = 'json'
          ..type = const cb.Reference('Map<String, Object?>')))
        ..body = cb.Code(body);

      // Add fromJson function parameters for generic types
      if (isGeneric && genericTypeNames.isNotEmpty) {
        for (final typeName in genericTypeNames) {
          c.requiredParameters.add(cb.Parameter((p) => p
            ..name = 'fromJson$typeName'
            ..type = cb.Reference('$typeName Function(Object? json)')));
        }
      }
    });
  }

  /// Extracts generic type parameter names from the visitor.
  List<String> _extractGenericTypeNames(FactoryModelVisitor visitor) {
    if (!visitor.isGeneric || visitor.genericTypes.isEmpty) {
      return [];
    }

    return visitor.genericTypes
        .map((t) => t.getDisplayString())
        .toList();
  }

  /// Builds the field mapping expression for a single property.
  String _buildFieldMapping(
    FactoryModelField property,
    bool isGeneric,
    List<String> genericTypeNames,
  ) {
    final jsonKey = property.fieldName ?? property.name;
    final cleanType = property.type.replaceAll('?', '');
    final isNullable = property.type.endsWith('?');
    final isGenericType = genericTypeNames.contains(cleanType);
    final cleanListType = property.listType.replaceAll('?', '');
    final isGenericListType = genericTypeNames.contains(cleanListType);

    // Handle List types
    if (property.isDartList) {
      return _buildListMapping(
        property,
        isGeneric,
        isGenericListType,
        jsonKey,
        cleanListType,
        isNullable,
      );
    }

    // Handle Map types
    if (property.isDartMap) {
      return _buildMapMapping(property, jsonKey, isNullable);
    }

    // Handle generic type parameters (e.g., T, I)
    if (isGeneric && isGenericType) {
      return _buildGenericTypeMapping(property, jsonKey, cleanType, isNullable);
    }

    // Handle nested class types
    if (property.isClass) {
      return _buildNestedObjectMapping(property, jsonKey, isNullable);
    }

    // Handle primitive types
    return _buildPrimitiveMapping(property, jsonKey);
  }

  /// Builds mapping for List types.
  String _buildListMapping(
    FactoryModelField property,
    bool isGeneric,
    bool isGenericListType,
    String jsonKey,
    String cleanListType,
    bool isNullableList,
  ) {
    final listType = property.listType;

    // Null safety wrapper
    String nullCheck = isNullableList ? "json['$jsonKey'] == null ? null : " : '';

    // Generic list type (e.g., List<T>)
    if (isGeneric && isGenericListType) {
      return '''${nullCheck}JsonDatatypeMapper.mapGenericListForTypeParameter<$cleanListType>(
        json['$jsonKey'] as List?,
        fromJson$cleanListType,
      )''';
    }

    // List of class objects
    if (property.listTypeIsClass) {
      return '''${nullCheck}JsonDatatypeMapper.mapGenericList<$listType>(
        json['$jsonKey'] as List?,
        (e) => $listType.fromJson(e as Map<String, Object?>),
      )''';
    }

    // List of primitives
    return '''${nullCheck}JsonDatatypeMapper.mapGenericList<$listType>(
        json['$jsonKey'] as List?,
        (e) => e as $listType,
      )''';
  }

  /// Builds mapping for Map types.
  String _buildMapMapping(
    FactoryModelField property,
    String jsonKey,
    bool isNullable,
  ) {
    if (isNullable) {
      return "json['$jsonKey'] as ${property.type}";
    }
    return "(json['$jsonKey'] as ${property.type}?) ?? <String, dynamic>{}";
  }

  /// Builds mapping for generic type parameters.
  String _buildGenericTypeMapping(
    FactoryModelField property,
    String jsonKey,
    String cleanType,
    bool isNullable,
  ) {
    if (isNullable) {
      return '''json['$jsonKey'] == null 
        ? null 
        : fromJson$cleanType(json['$jsonKey'])''';
    }
    return "fromJson$cleanType(json['$jsonKey'])";
  }

  /// Builds mapping for nested object types.
  String _buildNestedObjectMapping(
    FactoryModelField property,
    String jsonKey,
    bool isNullable,
  ) {
    final cleanType = property.type.replaceAll('?', '');

    if (isNullable) {
      return '''JsonDatatypeMapper.mapNullableNestedObject<$cleanType>(
        json,
        '$jsonKey',
        (map) => $cleanType.fromJson(map),
      )''';
    }
    return '''JsonDatatypeMapper.mapNestedObject<$cleanType>(
        json,
        '$jsonKey',
        (map) => $cleanType.fromJson(map),
      )''';
  }

  /// Builds mapping for primitive types.
  String _buildPrimitiveMapping(FactoryModelField property, String jsonKey) {
    final hasDefault = property.value != null;

    return '''JsonDatatypeMapper.mapForGeneric<${property.type}>(
        json,
        '$jsonKey',
        defaultValue: ${property.value ?? 'null'},
        mustWithDefault: $hasDefault,
      )''';
  }
}
