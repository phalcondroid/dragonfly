import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import '../visitor/factory_model_visitor.dart';
import '../models/factory_model_metadata.dart';

class FactoryModelRegistry {
  static final _factoryModelChecker = TypeChecker.fromRuntime(FactoryModel);

  /// Native/primitive types that are not classes
  static const _nativeTypes = {
    'int',
    'double',
    'num',
    'String',
    'bool',
    'dynamic',
    'Object',
    'void',
    'Null',
    'int?',
    'double?',
    'num?',
    'String?',
    'bool?',
    'Object?',
  };

  /// Scans all files and collects metadata for @FactoryModel annotated classes
  static Future<Map<String, FactoryModelMetadata>> collectMetadata(
    BuildStep buildStep,
  ) async {
    final registry = <String, FactoryModelMetadata>{};
    final glob = Glob('lib/**.dart');

    await for (final assetId in buildStep.findAssets(glob)) {
      try {
        final library = await buildStep.resolver.libraryFor(assetId);
        for (final element in library.topLevelElements) {
          if (element is ClassElement &&
              _factoryModelChecker.hasAnnotationOf(element)) {
            final metadata = _extractMetadata(element, assetId.path);
            if (metadata != null) {
              registry[metadata.modelName] = metadata;
            }
          }
        }
      } catch (e) {
        // Ignore files that can't be resolved
        continue;
      }
    }
    return registry;
  }

  static FactoryModelMetadata? _extractMetadata(
    ClassElement element,
    String importPath,
  ) {
    final annotation = _factoryModelChecker.firstAnnotationOf(element);
    if (annotation == null) return null;

    final reader = ConstantReader(annotation);
    final isGeneric = reader.peek('generic')?.boolValue ?? false;
    final isList = reader.peek('isList')?.boolValue ?? false;

    final visitor = FactoryModelVisitor();
    element.visitChildren(visitor);

    // Extract all generic type parameters
    final genericTypeParams = _extractGenericTypeParams(element);
    final genericParamNames = genericTypeParams.map((g) => g.name).toSet();

    // Extract fromJson factory info
    final fromJsonInfo = _extractFromJsonInfo(element, genericParamNames);
    //print(
    //    "====>>>>>>>>> element registry ${element.name} - ${element.displayName}");

    return FactoryModelMetadata(
      modelName: element.name,
      importPath: importPath,
      isGeneric: isGeneric,
      isList: isList,
      hasFromJson: fromJsonInfo.hasFromJson,
      genericTypeParams: genericTypeParams,
      fromJsonParams: fromJsonInfo.params,
      fromJsonRequiresConverter: fromJsonInfo.requiresConverter,
      fields: visitor.properties
          .map((p) => _createFieldMetadata(p, genericParamNames))
          .toList(),
    );
  }

  /// Extract all generic type parameters from a class
  static List<GenericTypeParamMetadata> _extractGenericTypeParams(
    ClassElement element,
  ) {
    final params = <GenericTypeParamMetadata>[];

    for (var i = 0; i < element.typeParameters.length; i++) {
      final typeParam = element.typeParameters[i];

      // Get the bound if any (e.g., T extends Object)
      String? bound;
      if (typeParam.bound != null &&
          typeParam.bound!.getDisplayString(withNullability: false) !=
              'Object') {
        bound = typeParam.bound!.getDisplayString(withNullability: false);
      }

      params.add(GenericTypeParamMetadata(
        name: typeParam.name,
        bound: bound,
        index: i,
      ));
    }

    return params;
  }

  /// Extract fromJson factory constructor information
  static ({
    bool hasFromJson,
    List<FromJsonParamMetadata> params,
    bool requiresConverter
  }) _extractFromJsonInfo(
    ClassElement element,
    Set<String> genericParamNames,
  ) {
    final fromJsonConstructor = element.constructors
        .where((c) => c.isFactory && c.name == 'fromJson')
        .firstOrNull;

    if (fromJsonConstructor == null) {
      return (hasFromJson: false, params: [], requiresConverter: false);
    }

    final params = <FromJsonParamMetadata>[];
    var requiresConverter = false;

    for (final param in fromJsonConstructor.parameters) {
      final paramType = param.type.getDisplayString(withNullability: true);

      // Check if this is a generic converter function
      final converterInfo =
          _checkGenericConverter(param.type, genericParamNames);

      if (converterInfo.isConverter) {
        requiresConverter = true;
      }

      // Check if this is the JSON map parameter
      final isJsonParam = paramType.startsWith('Map<String,') ||
          paramType == 'Map<String, dynamic>' ||
          paramType == 'Map<String, Object?>';

      params.add(FromJsonParamMetadata(
        name: param.name,
        type: paramType,
        isRequired: param.isRequired,
        isPositional: param.isPositional,
        isJsonParam: isJsonParam,
        isGenericConverter: converterInfo.isConverter,
        converterForGeneric: converterInfo.genericName,
      ));
    }

    return (
      hasFromJson: true,
      params: params,
      requiresConverter: requiresConverter
    );
  }

  /// Check if a type is a generic converter function like `T Function(Object?)`
  static ({bool isConverter, String? genericName}) _checkGenericConverter(
    DartType type,
    Set<String> genericParamNames,
  ) {
    if (type is! FunctionType) {
      return (isConverter: false, genericName: null);
    }

    final returnTypeStr =
        type.returnType.getDisplayString(withNullability: false);

    // Check if the return type matches any of our generic params
    if (genericParamNames.contains(returnTypeStr)) {
      return (isConverter: true, genericName: returnTypeStr);
    }

    return (isConverter: false, genericName: null);
  }

  /// Create field metadata with generic type usage detection
  static FactoryModelFieldMetadata _createFieldMetadata(
    dynamic property, // FactoryModelField from visitor
    Set<String> genericParamNames,
  ) {
    final type = property.type as String;
    final name = property.name as String;
    final isClass = property.isClass as bool;
    final isDartList = property.isDartList as bool;
    final isDartMap = property.isDartMap as bool;
    final isDartSet = property.isDartSet as bool;
    final listType = property.listType as String?;
    final isNullable = type.endsWith('?');

    // Detect generic usage
    final genericInfo = _detectGenericUsage(
      type: type,
      isDartList: isDartList,
      isDartMap: isDartMap,
      isDartSet: isDartSet,
      listType: listType,
      genericParamNames: genericParamNames,
    );

    // Determine inner type
    String? innerType;
    if (isDartList || isDartSet) {
      innerType = listType;
    } else if (isDartMap) {
      // Extract value type from Map<K, V>
      innerType = _extractMapValueType(type);
    }

    // Check if inner type is a class (not native type and not generic param)
    final innerTypeIsClass = innerType != null &&
        !_nativeTypes.contains(innerType) &&
        !_nativeTypes.contains('$innerType?') &&
        !genericParamNames.contains(innerType) &&
        !genericParamNames.contains(innerType.replaceAll('?', ''));

    return FactoryModelFieldMetadata(
      name: name,
      type: type,
      isClass: isClass,
      isList: isDartList,
      isMap: isDartMap,
      isSet: isDartSet,
      isNullable: isNullable,
      listInnerType: isDartList ? listType : null,
      usesGenericType: genericInfo.usesGeneric,
      genericUsage: genericInfo.usage,
      genericParamName: genericInfo.paramName,
      innerType: innerType,
      innerTypeIsClass: innerTypeIsClass,
    );
  }

  /// Detect how a generic type parameter is used in a field type
  static ({bool usesGeneric, GenericUsage usage, String? paramName})
      _detectGenericUsage({
    required String type,
    required bool isDartList,
    required bool isDartMap,
    required bool isDartSet,
    required String? listType,
    required Set<String> genericParamNames,
  }) {
    // Remove nullability for checking
    final cleanType = type.replaceAll('?', '');

    // Check for direct generic usage: T or T?
    for (final genericName in genericParamNames) {
      if (cleanType == genericName) {
        return (
          usesGeneric: true,
          usage: GenericUsage.direct,
          paramName: genericName
        );
      }
    }

    // Check for List<T>
    if (isDartList && listType != null) {
      final cleanListType = listType.replaceAll('?', '');
      for (final genericName in genericParamNames) {
        if (cleanListType == genericName) {
          return (
            usesGeneric: true,
            usage: GenericUsage.list,
            paramName: genericName
          );
        }
      }
    }

    // Check for Set<T>
    if (isDartSet && listType != null) {
      final cleanSetType = listType.replaceAll('?', '');
      for (final genericName in genericParamNames) {
        if (cleanSetType == genericName) {
          return (
            usesGeneric: true,
            usage: GenericUsage.set,
            paramName: genericName
          );
        }
      }
    }

    // Check for Map<K, T> or Map<T, V>
    if (isDartMap) {
      final mapTypes = _extractMapKeyValueTypes(type);
      if (mapTypes != null) {
        final cleanKey = mapTypes.key.replaceAll('?', '');
        final cleanValue = mapTypes.value.replaceAll('?', '');

        for (final genericName in genericParamNames) {
          if (cleanValue == genericName) {
            return (
              usesGeneric: true,
              usage: GenericUsage.mapValue,
              paramName: genericName
            );
          }
          if (cleanKey == genericName) {
            return (
              usesGeneric: true,
              usage: GenericUsage.mapKey,
              paramName: genericName
            );
          }
        }
      }
    }

    // Check if type contains generic in nested way (e.g., List<List<T>>)
    for (final genericName in genericParamNames) {
      if (type.contains('<$genericName>') ||
          type.contains('<$genericName,') ||
          type.contains(', $genericName>') ||
          type.contains('<$genericName?>') ||
          type.contains('<$genericName?,') ||
          type.contains(', $genericName?>')) {
        // Determine the outer wrapper
        if (isDartList) {
          return (
            usesGeneric: true,
            usage: GenericUsage.list,
            paramName: genericName
          );
        } else if (isDartMap) {
          return (
            usesGeneric: true,
            usage: GenericUsage.mapValue,
            paramName: genericName
          );
        } else if (isDartSet) {
          return (
            usesGeneric: true,
            usage: GenericUsage.set,
            paramName: genericName
          );
        }
        return (
          usesGeneric: true,
          usage: GenericUsage.direct,
          paramName: genericName
        );
      }
    }

    return (usesGeneric: false, usage: GenericUsage.none, paramName: null);
  }

  /// Extract key and value types from a Map type string
  static ({String key, String value})? _extractMapKeyValueTypes(String type) {
    if (!type.startsWith('Map<')) return null;

    // Find the content between Map< and >
    final startIndex = 4; // "Map<".length
    final endIndex = type.lastIndexOf('>');
    if (endIndex == -1) return null;

    final content = type.substring(startIndex, endIndex);

    // Split by comma, handling nested generics
    var depth = 0;
    var splitIndex = -1;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '<') {
        depth++;
      } else if (char == '>') {
        depth--;
      } else if (char == ',' && depth == 0) {
        splitIndex = i;
        break;
      }
    }

    if (splitIndex == -1) return null;

    final key = content.substring(0, splitIndex).trim();
    final value = content.substring(splitIndex + 1).trim();

    return (key: key, value: value);
  }

  /// Extract value type from a Map type string
  static String? _extractMapValueType(String type) {
    final types = _extractMapKeyValueTypes(type);
    return types?.value;
  }
}
