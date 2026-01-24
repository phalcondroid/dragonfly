import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/helper/metadata_extractor.dart';
import 'package:dragonfly_builder/builder/models/factory_model_field.dart';
import 'package:source_gen/source_gen.dart';

class FactoryModelVisitor extends SimpleElementVisitor<void> {
  List<FactoryModelField> properties = [];
  String? className;
  List<DartType> genericTypes = [];
  bool isGeneric = false;

  @override
  void visitClassElement(ClassElement e) {
    print("[TYPE CLASS CONSTURCTOR] ${e.typeParameters}");
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    if (element.isFactory && element.displayName.contains(".fromJson")) {
      return;
    }
    genericTypes.addAll(element.returnType.typeArguments);
    className = element.displayName;
    for (var e in element.parameters) {
      fillProperty(e, e.type);
    }
  }

  @override
  void visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    fillProperty(element as ParameterElement, element.type);
  }

  DartObject? getAnnotation(element) => const TypeChecker.fromRuntime(Field)
      .firstAnnotationOf(element, throwOnUnresolved: false);

  void fillProperty(ParameterElement e, DartType type) {
    final (isFieldName, fieldName, defaultValue) =
        resolveAnnotationFieldName(e, type);

    final bool isClass = !(e.type.isDartCoreBool ||
        e.type.isDartCoreDouble ||
        e.type.isDartCoreInt ||
        e.type.isDartCoreString ||
        e.type.isDartCoreList ||
        e.type.isDartCoreMap ||
        e.type.isDartCoreSet ||
        e.type.isDartCoreObject);

    String listType = MedatadaExtractor.getContentOfTag(
        type.getDisplayString(withNullability: true));

    final bool isListClass = e.type.isDartCoreList &&
        !("bool" == listType ||
            "bool?" == listType ||
            "double" == listType ||
            "double?" == listType ||
            "int" == listType ||
            "int?" == listType ||
            "String" == listType ||
            "String?" == listType ||
            "List" == listType ||
            "Map" == listType ||
            "Set" == listType ||
            "Object" == listType ||
            "Object?" == listType);

    //print(
    //    " [==== hard code field ] ${fieldName}, ${e.displayName} =  ${e.type} - (${e}) :: $isListClass \n\n");

    properties.add(FactoryModelField(
        name: e.displayName,
        fieldName: fieldName,
        isFieldName: isFieldName,
        value: defaultValue,
        type: type.getDisplayString(withNullability: true),
        isDartList: e.type.isDartCoreList,
        isDartMap: e.type.isDartCoreMap,
        isDartSet: e.type.isDartCoreSet,
        isNullable: e.type.isDartCoreNull,
        isFinal: e.isFinal,
        isClass: isClass,
        isRequired: e.isRequiredNamed,
        listType: MedatadaExtractor.getContentOfTag(
            type.getDisplayString(withNullability: true)),
        listTypeIsClass: isListClass,
        rawType: type));
  }

  (bool, String?, Object?) resolveAnnotationFieldName(element, DartType type) {
    final rawAnnotation = getAnnotation(element);
    if (rawAnnotation != null) {
      final annotation = ConstantReader(rawAnnotation);
      bool isFieldName = false;
      String fieldName = "";
      Object? defaultValue = "";
      if (!annotation.read("field").isNull &&
          annotation.read("field").stringValue.isNotEmpty) {
        fieldName = annotation.read("field").stringValue;
      }
      final defaultValAnn = annotation.read("value");
      if (!defaultValAnn.isNull) {
        defaultValue = getDataTypeDefaultValue(defaultValAnn, type);
      }
      return (isFieldName, fieldName, defaultValue);
    }
    return (false, null, null);
  }

  Object? getDataTypeDefaultValue(ConstantReader ann, DartType type) =>
      switch (type.getDisplayString(withNullability: true)) {
        "String" => "'${ann.stringValue}'",
        "int" => ann.intValue,
        "double" => ann.doubleValue,
        "bool" => ann.boolValue,
        "List" => ann.listValue,
        "Map" => ann.mapValue,
        "Set" => ann.setValue,
        "Object" => ann.objectValue,
        "DateTime" => "DateTime('${ann.objectValue.toStringValue()}')",
        _ => ann.objectValue
      };
}
