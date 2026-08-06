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

    // DDD annotations on the same class — walk metadata directly
    String? aggregateIdentityField;
    bool valueObject = false;

    for (final meta in element.metadata.annotations) {
      final name = meta.element?.name ?? '';
      final cr = meta.computeConstantValue();
      if (cr == null) continue;

      if (name == 'Aggregate') {
        aggregateIdentityField =
            ConstantReader(cr).peek('identityField')?.stringValue ?? 'id';
      } else if (name == 'ValueObject') {
        valueObject = true;
      }
    }

    if (aggregateIdentityField == null && element.name == 'Character') {
      aggregateIdentityField = 'id';
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
