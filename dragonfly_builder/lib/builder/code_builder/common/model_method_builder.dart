import 'package:code_builder/code_builder.dart' as cb;
import 'package:dragonfly_builder/builder/models/factory_model_field.dart';

/// Utility class for building common model methods like equals, hashCode, toString, etc.
class ModelMethodBuilder {
  /// Builds an equality operator (==) method.
  ///
  /// Generates code like:
  /// ```dart
  /// @override
  /// bool operator ==(Object other) {
  ///   if (identical(this, other)) return true;
  ///   return other is ClassName &&
  ///       other.field1 == field1 &&
  ///       other.field2 == field2;
  /// }
  /// ```
  static cb.Method buildEqualsOperator(
    String className,
    List<FactoryModelField> properties,
  ) {
    final conditions = properties.map((p) {
      if (p.isDartList) {
        return '_listEquals(other.${p.name}, ${p.name})';
      }
      if (p.isDartMap) {
        return '_mapEquals(other.${p.name}, ${p.name})';
      }
      if (p.isDartSet) {
        return '_setEquals(other.${p.name}, ${p.name})';
      }
      return 'other.${p.name} == ${p.name}';
    }).join(' && ');

    final body = '''
if (identical(this, other)) return true;
return other is $className${conditions.isEmpty ? '' : ' && $conditions'};
''';

    return cb.Method((m) => m
      ..name = 'operator =='
      ..annotations.add(const cb.Reference('override'))
      ..returns = const cb.Reference('bool')
      ..requiredParameters.add(cb.Parameter((p) => p
        ..name = 'other'
        ..type = const cb.Reference('Object')))
      ..body = cb.Code(body));
  }

  /// Builds a hashCode getter.
  ///
  /// Generates code like:
  /// ```dart
  /// @override
  /// int get hashCode => field1.hashCode ^ field2.hashCode;
  /// ```
  static cb.Method buildHashCode(List<FactoryModelField> properties) {
    String body;
    if (properties.isEmpty) {
      body = 'return runtimeType.hashCode;';
    } else if (properties.length == 1) {
      body = 'return ${properties.first.name}.hashCode;';
    } else {
      final hashParts = properties.map((p) => '${p.name}.hashCode').join(' ^ ');
      body = 'return $hashParts;';
    }

    return cb.Method((m) => m
      ..name = 'hashCode'
      ..annotations.add(const cb.Reference('override'))
      ..returns = const cb.Reference('int')
      ..type = cb.MethodType.getter
      ..body = cb.Code(body));
  }

  /// Builds a toString method.
  ///
  /// Generates code like:
  /// ```dart
  /// @override
  /// String toString() {
  ///   return 'ClassName(field1: $field1, field2: $field2)';
  /// }
  /// ```
  static cb.Method buildToString(
    String className,
    List<FactoryModelField> properties,
  ) {
    final fields = properties.map((p) => '${p.name}: \$${p.name}').join(', ');
    final body = "return '$className($fields)';";

    return cb.Method((m) => m
      ..name = 'toString'
      ..annotations.add(const cb.Reference('override'))
      ..returns = const cb.Reference('String')
      ..body = cb.Code(body));
  }

  /// Builds a toJson method that returns Map<String, dynamic>.
  ///
  /// Generates code like:
  /// ```dart
  /// Map<String, dynamic> toJson() {
  ///   return {
  ///     'field1': field1,
  ///     'field2': field2.toJson(),
  ///   };
  /// }
  /// ```
  static cb.Method buildToJson(
    List<FactoryModelField> properties, {
    bool isGeneric = false,
    List<String> genericTypes = const [],
  }) {
    final entries = <String>[];

    for (final p in properties) {
      final jsonKey = p.fieldName ?? p.name;
      String valueExpr;

      if (isGeneric && genericTypes.contains(p.type.replaceAll('?', ''))) {
        // For generic types, we need a toJson function parameter
        valueExpr = 'toJson${p.type.replaceAll('?', '')}(${p.name})';
      } else if (p.isClass && !p.isDartList && !p.isDartMap && !p.isDartSet) {
        // Nested object with toJson
        if (p.type.endsWith('?')) {
          valueExpr = '${p.name}?.toJson()';
        } else {
          valueExpr = '${p.name}.toJson()';
        }
      } else if (p.isDartList && p.listTypeIsClass) {
        // List of objects
        if (isGeneric && genericTypes.contains(p.listType.replaceAll('?', ''))) {
          valueExpr =
              '${p.name}.map((e) => toJson${p.listType.replaceAll('?', '')}(e)).toList()';
        } else {
          valueExpr = '${p.name}.map((e) => e.toJson()).toList()';
        }
      } else if (p.isDartMap) {
        valueExpr = p.name;
      } else {
        valueExpr = p.name;
      }

      entries.add("'$jsonKey': $valueExpr");
    }

    final body = 'return {${entries.join(', ')}};';

    final method = cb.Method((m) {
      m
        ..name = 'toJson'
        ..returns = const cb.Reference('Map<String, dynamic>')
        ..body = cb.Code(body);

      // Add toJson function parameters for generic types
      if (isGeneric) {
        for (final genType in genericTypes) {
          m.requiredParameters.add(cb.Parameter((p) => p
            ..name = 'toJson$genType'
            ..type = cb.Reference('dynamic Function($genType value)')));
        }
      }
    });

    return method;
  }

  /// Builds a toMap method that returns Map<String, Object?>.
  ///
  /// Similar to toJson but with Object? type. Uses toJson() for nested objects
  /// since that is the standard serialization method all models implement.
  static cb.Method buildToMap(
    List<FactoryModelField> properties, {
    bool isGeneric = false,
    List<String> genericTypes = const [],
  }) {
    final entries = <String>[];

    for (final p in properties) {
      final jsonKey = p.fieldName ?? p.name;
      String valueExpr;

      if (isGeneric && genericTypes.contains(p.type.replaceAll('?', ''))) {
        // For generic types, use the provided toJson function
        valueExpr = 'toJson${p.type.replaceAll('?', '')}(${p.name})';
      } else if (p.isClass && !p.isDartList && !p.isDartMap && !p.isDartSet) {
        // Nested object - use toJson() as it's the standard method
        if (p.type.endsWith('?')) {
          valueExpr = '${p.name}?.toJson()';
        } else {
          valueExpr = '${p.name}.toJson()';
        }
      } else if (p.isDartList && p.listTypeIsClass) {
        // List of objects - use toJson()
        if (isGeneric && genericTypes.contains(p.listType.replaceAll('?', ''))) {
          valueExpr =
              '${p.name}.map((e) => toJson${p.listType.replaceAll('?', '')}(e)).toList()';
        } else {
          valueExpr = '${p.name}.map((e) => e.toJson()).toList()';
        }
      } else {
        valueExpr = p.name;
      }

      entries.add("'$jsonKey': $valueExpr");
    }

    final body = 'return <String, Object?>{${entries.join(', ')}};';

    final method = cb.Method((m) {
      m
        ..annotations.add(const cb.Reference('override'))
        ..name = 'toMap'
        ..returns = const cb.Reference('Map<String, Object?>')
        ..body = cb.Code(body);

      // Use toJson function parameters for generic types (same as toJson method)
      if (isGeneric) {
        for (final genType in genericTypes) {
          m.requiredParameters.add(cb.Parameter((p) => p
            ..name = 'toJson$genType'
            ..type = cb.Reference('dynamic Function($genType value)')));
        }
      }
    });

    return method;
  }

  /// Builds a copyWith method.
  ///
  /// Generates code like:
  /// ```dart
  /// ClassName copyWith({
  ///   String? field1,
  ///   int? field2,
  /// }) {
  ///   return ClassName(
  ///     field1: field1 ?? this.field1,
  ///     field2: field2 ?? this.field2,
  ///   );
  /// }
  /// ```
  static cb.Method buildCopyWith(
    String className,
    String generatedClassName,
    List<FactoryModelField> properties, {
    bool isGeneric = false,
    List<String> genericTypes = const [],
  }) {
    final params = properties.map((p) {
      // Make all parameters nullable for copyWith
      String type = p.type;
      if (!type.endsWith('?')) {
        type = '$type?';
      }

      return cb.Parameter((param) => param
        ..name = p.name
        ..named = true
        ..type = cb.Reference(type));
    }).toList();

    final constructorArgs = properties.map((p) {
      return '${p.name}: ${p.name} ?? this.${p.name}';
    }).join(', ');

    final genericSuffix =
        isGeneric && genericTypes.isNotEmpty ? '<${genericTypes.join(', ')}>' : '';

    final body = 'return $generatedClassName$genericSuffix($constructorArgs);';

    return cb.Method((m) => m
      ..annotations.add(const cb.Reference('override'))
      ..name = 'copyWith'
      ..returns = cb.Reference('$className$genericSuffix')
      ..optionalParameters.addAll(params)
      ..body = cb.Code(body));
  }

  /// Builds helper methods for deep equality checks.
  static List<cb.Method> buildEqualityHelpers() {
    return [
      cb.Method((m) => m
        ..name = '_listEquals'
        ..static = true
        ..returns = const cb.Reference('bool')
        ..types.add(const cb.Reference('T'))
        ..requiredParameters.addAll([
          cb.Parameter((p) => p
            ..name = 'a'
            ..type = const cb.Reference('List<T>?')),
          cb.Parameter((p) => p
            ..name = 'b'
            ..type = const cb.Reference('List<T>?')),
        ])
        ..body = cb.Code('''
if (identical(a, b)) return true;
if (a == null || b == null) return false;
if (a.length != b.length) return false;
for (int i = 0; i < a.length; i++) {
  if (a[i] != b[i]) return false;
}
return true;
''')),
      cb.Method((m) => m
        ..name = '_mapEquals'
        ..static = true
        ..returns = const cb.Reference('bool')
        ..types.addAll([
          const cb.Reference('K'),
          const cb.Reference('V'),
        ])
        ..requiredParameters.addAll([
          cb.Parameter((p) => p
            ..name = 'a'
            ..type = const cb.Reference('Map<K, V>?')),
          cb.Parameter((p) => p
            ..name = 'b'
            ..type = const cb.Reference('Map<K, V>?')),
        ])
        ..body = cb.Code('''
if (identical(a, b)) return true;
if (a == null || b == null) return false;
if (a.length != b.length) return false;
for (final key in a.keys) {
  if (!b.containsKey(key) || a[key] != b[key]) return false;
}
return true;
''')),
      cb.Method((m) => m
        ..name = '_setEquals'
        ..static = true
        ..returns = const cb.Reference('bool')
        ..types.add(const cb.Reference('T'))
        ..requiredParameters.addAll([
          cb.Parameter((p) => p
            ..name = 'a'
            ..type = const cb.Reference('Set<T>?')),
          cb.Parameter((p) => p
            ..name = 'b'
            ..type = const cb.Reference('Set<T>?')),
        ])
        ..body = cb.Code('''
if (identical(a, b)) return true;
if (a == null || b == null) return false;
if (a.length != b.length) return false;
return a.containsAll(b);
''')),
    ];
  }
}
