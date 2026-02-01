import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dragonfly_builder/builder/models/factory_model_field.dart';

/// Represents a variant (factory constructor) in a sealed class.
class SealedVariant {
  /// The name of the variant (e.g., 'loading', 'getUser' from UserEvent.loading, UserEvent.getUser).
  final String name;

  /// The full constructor name (e.g., 'UserEventLoading').
  final String className;

  /// The parameters of this variant.
  final List<FactoryModelField> parameters;

  /// Whether this is the default (unnamed) factory.
  final bool isDefault;

  const SealedVariant({
    required this.name,
    required this.className,
    required this.parameters,
    this.isDefault = false,
  });
}

/// Visitor for sealed classes (used for EventModel and StateModel).
///
/// This visitor extracts information about factory constructors in sealed classes
/// to generate pattern matching methods and subclasses.
class SealedClassVisitor extends SimpleElementVisitor<void> {
  /// The name of the base sealed class.
  String? className;

  /// List of variants (factory constructors).
  List<SealedVariant> variants = [];

  /// Generic type parameters of the class.
  List<DartType> genericTypes = [];

  /// Whether the class has generic type parameters.
  bool isGeneric = false;

  @override
  void visitConstructorElement(ConstructorElement element) {
    if (!element.isFactory) return;

    // Get the class name from the first factory constructor
    className ??= element.enclosingElement3.name;

    // Check for generic types
    final classElement = element.enclosingElement3 as ClassElement;
    if (classElement.typeParameters.isNotEmpty) {
      isGeneric = true;
      genericTypes =
          classElement.typeParameters.map((t) => t.bound ?? t.instantiate(nullabilitySuffix: NullabilitySuffix.none)).toList();
    }

    // Extract variant name (part after the dot in factory ClassName.variantName)
    final variantName = element.name.isEmpty ? '' : element.name;
    final isDefault = variantName.isEmpty;

    // Skip fromJson factories
    if (variantName == 'fromJson') return;

    // Generate the subclass name
    final subclassName = _generateSubclassName(className!, variantName);

    // Extract parameters
    final parameters = _extractParameters(element);

    variants.add(SealedVariant(
      name: variantName,
      className: subclassName,
      parameters: parameters,
      isDefault: isDefault,
    ));
  }

  /// Generates a subclass name from the base class and variant name.
  ///
  /// Examples:
  /// - UserEvent + 'loading' -> UserEventLoading
  /// - UserEvent + 'getUser' -> UserEventGetUser
  /// - UserEvent + '' (default) -> _$UserEvent (implementation class)
  String _generateSubclassName(String baseClassName, String variantName) {
    if (variantName.isEmpty) {
      return '_\$$baseClassName';
    }

    // Capitalize first letter of variant name
    final capitalizedVariant =
        variantName[0].toUpperCase() + variantName.substring(1);
    return '$baseClassName$capitalizedVariant';
  }

  /// Extracts parameters from a constructor element.
  List<FactoryModelField> _extractParameters(ConstructorElement element) {
    return element.parameters.map((param) {
      final type = param.type;
      final typeString = type.getDisplayString(withNullability: true);

      final bool isClass = !(type.isDartCoreBool ||
          type.isDartCoreDouble ||
          type.isDartCoreInt ||
          type.isDartCoreString ||
          type.isDartCoreList ||
          type.isDartCoreMap ||
          type.isDartCoreSet ||
          type.isDartCoreObject);

      String listType = '';
      bool listTypeIsClass = false;

      if (type.isDartCoreList) {
        listType = _extractGenericType(typeString);
        listTypeIsClass = !_isPrimitiveType(listType);
      }

      return FactoryModelField(
        name: param.name,
        fieldName: null,
        isFieldName: false,
        value: param.hasDefaultValue ? param.defaultValueCode : null,
        type: typeString,
        isDartList: type.isDartCoreList,
        isDartMap: type.isDartCoreMap,
        isDartSet: type.isDartCoreSet,
        isNullable: typeString.endsWith('?'),
        isFinal: param.isFinal,
        isClass: isClass,
        isRequired: param.isRequiredNamed || param.isRequiredPositional,
        rawType: type,
        listType: listType,
        listTypeIsClass: listTypeIsClass,
      );
    }).toList();
  }

  /// Extracts the generic type from a type string like "List<String>".
  String _extractGenericType(String typeString) {
    final match = RegExp(r'<(.+?)>').firstMatch(typeString);
    return match?.group(1) ?? 'dynamic';
  }

  /// Checks if a type is a primitive type.
  bool _isPrimitiveType(String type) {
    final cleanType = type.replaceAll('?', '');
    return const [
      'bool',
      'double',
      'int',
      'num',
      'String',
      'dynamic',
      'Object',
    ].contains(cleanType);
  }

  /// Resets the visitor state for reuse.
  void reset() {
    className = null;
    variants = [];
    genericTypes = [];
    isGeneric = false;
  }
}
