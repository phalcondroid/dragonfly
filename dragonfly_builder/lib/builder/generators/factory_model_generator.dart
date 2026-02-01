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
/// - An abstract contract class with getters
///
/// Example input:
/// ```dart
/// @FactoryModel()
/// abstract interface class User implements _$UserContract {
///   factory User({required String name, required int age}) = _$User;
///   factory User.fromJson(Map<String, Object?> json) = _$User.fromJson;
/// }
/// ```
///
/// Example output:
/// ```dart
/// class _$User implements FactoryModelWatcher, User {
///   _$User({required this.name, required this.age});
///
///   factory _$User.fromJson(Map<String, Object?> json) {
///     return _$User(
///       name: JsonDatatypeMapper.mapForGeneric<String>(json, 'name'),
///       age: JsonDatatypeMapper.mapForGeneric<int>(json, 'age'),
///     );
///   }
///
///   @override
///   final String name;
///
///   @override
///   final int age;
///
///   @override
///   Map<String, dynamic> toJson() => {'name': name, 'age': age};
///
///   @override
///   bool operator ==(Object other) => ...;
///
///   @override
///   int get hashCode => ...;
///
///   @override
///   String toString() => 'User(name: $name, age: $age)';
/// }
///
/// abstract class _$UserContract {
///   String get name;
///   int get age;
/// }
/// ```
class FactoryModelGenerator extends GeneratorForAnnotation<FactoryModel> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = FactoryModelVisitor();
    element.visitChildren(visitor);

    // Read configuration from annotation
    final config = FactoryModelConfig.fromAnnotation(
      generic: annotation.peek('generic')?.boolValue,
      isList: annotation.peek('isList')?.boolValue,
      copyWith: annotation.peek('copyWith')?.boolValue,
      toJson: annotation.peek('toJson')?.boolValue,
      toMap: annotation.peek('toMap')?.boolValue,
      equals: annotation.peek('equals')?.boolValue,
      toStringMethod: annotation.peek('toStringMethod')?.boolValue,
    );

    try {
      final properties = visitor.properties;
      final builder = CommonFactoryModelBuilder();

      final String model = builder.createGenericModel(visitor, properties, config);
      final String interfaceContract =
          builder.createAbstractInterface(visitor, properties, config.isGeneric);

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
