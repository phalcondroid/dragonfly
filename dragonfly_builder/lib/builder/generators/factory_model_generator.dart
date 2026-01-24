import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dragonfly_builder/builder/code_builder/factory_model/common_factory_model_builder.dart';
import 'package:dragonfly_builder/builder/visitor/factory_model_visitor.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:source_gen/source_gen.dart';

class FactoryModelGenerator extends GeneratorForAnnotation<FactoryModel> {
  final visitor = FactoryModelVisitor();

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    element.visitChildren(visitor);

    final bool isGeneric = annotation.peek('generic')?.boolValue ?? false;
    try {
      final properties = visitor.properties;
      final String interfaceContract = CommonFactoryModelBuilder()
          .createAbstractInterface(visitor, properties, isGeneric);
      final String model = CommonFactoryModelBuilder()
          .createGenericModel(visitor, properties, isGeneric);
      visitor.genericTypes = [];
      visitor.isGeneric = isGeneric;
      visitor.properties = [];
      return "$model \n $interfaceContract";
    } catch (e) {
      visitor.genericTypes = [];
      visitor.isGeneric = false;
      visitor.properties = [];
      print("========>> EXCEPTION ${e}");
      return "";
    }
  }
}
