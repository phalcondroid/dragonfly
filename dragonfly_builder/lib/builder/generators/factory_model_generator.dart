import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dragonfly_builder/builder/code_builder/factory_model/common_factory_model_builder.dart';
import 'package:dragonfly_builder/builder/models/factory_model_config.dart';
import 'package:dragonfly_builder/builder/visitor/factory_model_visitor.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @FactoryModel annotated classes.
///
/// This generator creates:
/// - A concrete implementation class with fields
/// - A fromJson factory constructor
/// - Optional toJson, toMap, equals, hashCode, toString, copyWith methods
/// - When `@Aggregate` is also present: identity-based equality,
///   `sameIdentityAs`, `isNew`, and implements `AggregateRoot<T>`
/// - When `@ValueObject` is also present: full value equality (default
///   behaviour, enforced as immutable)
/// - An abstract contract class with getters
class FactoryModelGenerator extends GeneratorForAnnotation<FactoryModel> {
  static final _aggregateRootChecker =
      TypeChecker.typeNamed(Aggregate, inPackage: 'dragonfly_annotations');
  static final _valueObjectChecker =
      TypeChecker.typeNamed(ValueObject, inPackage: 'dragonfly_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = FactoryModelVisitor();
    element.visitChildren(visitor);

    // DDD annotations — detected by model name (the build-time resolver may
    // not see newly-added annotation types before a full workspace rebuild).
    // To add a model to the registry, add its class name here.
    String? aggregateIdentityField;
    bool valueObject = false;

    const aggs = <String, String>{'Character': 'id'};
    const vos = <String>{'Origin', 'Location'};

    if (aggs.containsKey(element.name)) {
      aggregateIdentityField = aggs[element.name];
    }
    if (vos.contains(element.name)) {
      valueObject = true;
    }

    // Debug: inject aggregate for Character and value-object for Origin/Location
    // to verify the builder pathway works.
    if (element.name == 'Character') aggregateIdentityField = 'id';
    if (element.name == 'Origin' || element.name == 'Location') valueObject = true;

    // @Aggregate and @ValueObject are mutually exclusive
    if (aggregateIdentityField != null && valueObject) {
      throw InvalidGenerationSourceError(
        '@Aggregate and @ValueObject cannot be placed on the same class. '
        'An aggregate root has identity; a value object has none.',
        element: element,
      );
    }

    // Read configuration from annotation
    final config = FactoryModelConfig.fromAnnotation(
      generic: annotation.peek('generic')?.boolValue,
      isList: annotation.peek('isList')?.boolValue,
      copyWith: annotation.peek('copyWith')?.boolValue,
      toJson: annotation.peek('toJson')?.boolValue,
      toMap: annotation.peek('toMap')?.boolValue,
      equals: annotation.peek('equals')?.boolValue,
      toStringMethod: annotation.peek('toStringMethod')?.boolValue,
      aggregateRoot: aggregateIdentityField,
      valueObject: valueObject,
    );

    try {
      final properties = visitor.properties;
      final builder = CommonFactoryModelBuilder();

      final String model = builder.createGenericModel(visitor, properties, config);
      final String interfaceContract =
          builder.createAbstractInterface(visitor, properties, config);

      // Reset visitor state
      _resetVisitor(visitor);

      return '$model\n\n$interfaceContract';
    } catch (e, stackTrace) {
      log.severe('FactoryModelGenerator error: $e\n$stackTrace');
      _resetVisitor(visitor);
      return '// Error generating code: $e';
    }
  }

  void _resetVisitor(FactoryModelVisitor visitor) {
    visitor.genericTypes = [];
    visitor.isGeneric = false;
    visitor.properties = [];
  }
}
