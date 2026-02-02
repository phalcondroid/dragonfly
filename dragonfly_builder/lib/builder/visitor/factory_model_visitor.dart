import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/helper/metadata_extractor.dart';
import 'package:dragonfly_builder/builder/models/factory_model_field.dart';
import 'package:source_gen/source_gen.dart';

/// Visitor for extracting metadata from @FactoryModel annotated classes.
///
/// This visitor collects:
/// - Class name
/// - Generic type parameters
/// - Constructor parameters (converted to model fields)
/// - Field annotations for custom JSON mapping
class FactoryModelVisitor extends SimpleElementVisitor<void> {
  /// The properties extracted from the constructor parameters.
  List<FactoryModelField> properties = [];

  /// The name of the annotated class.
  String? className;

  /// The generic type parameters of the class.
  List<DartType> genericTypes = [];

  /// Whether the class has generic type parameters.
  bool isGeneric = false;

  /// Set of generic type parameter names for quick lookup.
  Set<String> _genericTypeNames = {};

  @override
  void visitClassElement(ClassElement element) {
    // Capture generic type parameters from class declaration
    if (element.typeParameters.isNotEmpty) {
      isGeneric = true;
      _genericTypeNames = element.typeParameters.map((t) => t.name).toSet();
    }
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    // Skip fromJson factories
    if (element.isFactory && element.name == 'fromJson') {
      return;
    }

    // Only process the first non-fromJson constructor
    if (className != null) {
      return;
    }

    // Get class name
    className = element.enclosingElement.name;

    // Capture generic types from the interface declaration
    final classElement = element.enclosingElement as ClassElement;
    if (classElement.typeParameters.isNotEmpty) {
      isGeneric = true;
      _genericTypeNames = classElement.typeParameters.map((t) => t.name).toSet();

      // Also capture the actual type arguments from return type
      genericTypes.addAll(element.returnType.typeArguments);

      // If no type arguments from return type, use the parameters themselves
      if (genericTypes.isEmpty) {
        for (final param in classElement.typeParameters) {
          // Create a simple type reference from the parameter name
          genericTypes.add(_createTypeFromParameter(param));
        }
      }
    }

    // Process constructor parameters
    for (final param in element.parameters) {
      _fillProperty(param, param.type);
    }
  }

  @override
  void visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    _fillProperty(element, element.type);
  }

  /// Creates a fake DartType from a TypeParameterElement for generic type handling.
  DartType _createTypeFromParameter(TypeParameterElement param) {
    // Return the bound if it exists, otherwise use the parameter's type
    return param.bound ?? param.instantiate(nullabilitySuffix: NullabilitySuffix.none);
  }

  /// Gets the @Field annotation from an element if present.
  DartObject? _getFieldAnnotation(Element element) {
    return const TypeChecker.fromRuntime(Field).firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
  }

  /// Extracts property information from a constructor parameter.
  void _fillProperty(ParameterElement param, DartType type) {
    final typeString = type.getDisplayString(withNullability: true);
    final cleanTypeString = typeString.replaceAll('?', '');

    // Check if this type is a generic type parameter
    final isGenericTypeParam = _genericTypeNames.contains(cleanTypeString);

    // Resolve Field annotation
    final (isFieldName, fieldName, defaultValue) =
        _resolveFieldAnnotation(param, type);

    // Determine if this is a class type (not primitive)
    final bool isClass = _isClassType(param.type, cleanTypeString);

    // Handle List types
    String listType = MedatadaExtractor.getContentOfTag(typeString);
    final bool isListClass =
        param.type.isDartCoreList && _isClassType(null, listType.replaceAll('?', ''));

    // Also check if the list contains a generic type parameter
    final bool isListGenericType =
        param.type.isDartCoreList && _genericTypeNames.contains(listType.replaceAll('?', ''));

    properties.add(FactoryModelField(
      name: param.displayName,
      fieldName: fieldName,
      isFieldName: isFieldName,
      value: defaultValue,
      type: typeString,
      isDartList: param.type.isDartCoreList,
      isDartMap: param.type.isDartCoreMap,
      isDartSet: param.type.isDartCoreSet,
      isNullable: typeString.endsWith('?'),
      isFinal: param.isFinal,
      isClass: isClass && !isGenericTypeParam,
      isRequired: param.isRequiredNamed || param.isRequiredPositional,
      listType: listType,
      listTypeIsClass: isListClass || isListGenericType,
      rawType: type,
    ));
  }

  /// Checks if a type is a class type (not a primitive).
  bool _isClassType(DartType? type, String typeString) {
    // Check against known primitives
    const primitives = {
      'bool',
      'int',
      'double',
      'num',
      'String',
      'List',
      'Map',
      'Set',
      'Object',
      'dynamic',
      'void',
      'Null',
      'Never',
    };

    if (primitives.contains(typeString)) {
      return false;
    }

    // Check if it's a generic type parameter
    if (_genericTypeNames.contains(typeString)) {
      return false;
    }

    // Use DartType checks if available
    if (type != null) {
      return !(type.isDartCoreBool ||
          type.isDartCoreDouble ||
          type.isDartCoreInt ||
          type.isDartCoreString ||
          type.isDartCoreList ||
          type.isDartCoreMap ||
          type.isDartCoreSet ||
          type.isDartCoreObject ||
          type.isDartCoreNull);
    }

    return true;
  }

  /// Resolves the @Field annotation values.
  (bool, String?, Object?) _resolveFieldAnnotation(
    ParameterElement element,
    DartType type,
  ) {
    final rawAnnotation = _getFieldAnnotation(element);

    if (rawAnnotation == null) {
      return (false, null, null);
    }

    final annotation = ConstantReader(rawAnnotation);
    bool hasFieldName = false;
    String? fieldName;
    Object? defaultValue;

    // Read field name
    final fieldReader = annotation.read('field');
    if (!fieldReader.isNull && fieldReader.stringValue.isNotEmpty) {
      hasFieldName = true;
      fieldName = fieldReader.stringValue;
    }

    // Read default value
    final valueReader = annotation.read('value');
    if (!valueReader.isNull) {
      defaultValue = _getDefaultValue(valueReader, type);
    }

    return (hasFieldName, fieldName, defaultValue);
  }

  /// Converts annotation value to appropriate Dart literal.
  Object? _getDefaultValue(ConstantReader reader, DartType type) {
    final typeString = type.getDisplayString(withNullability: false);

    return switch (typeString) {
      'String' => "'${reader.stringValue}'",
      'int' => reader.intValue,
      'double' => reader.doubleValue,
      'bool' => reader.boolValue,
      'List' => reader.listValue,
      'Map' => reader.mapValue,
      'Set' => reader.setValue,
      'DateTime' => "DateTime.parse('${reader.objectValue.toStringValue()}')",
      _ => reader.objectValue,
    };
  }

  /// Resets the visitor state for reuse.
  void reset() {
    properties = [];
    className = null;
    genericTypes = [];
    isGeneric = false;
    _genericTypeNames = {};
  }
}
