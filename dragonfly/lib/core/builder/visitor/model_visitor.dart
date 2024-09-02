import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly/core/builder/types/method_repository_type.dart';
import 'package:dragonfly/core/builder/types/return_type.dart';
import 'package:dragonfly/core/builder/visitor/header_helper.dart';
import 'package:dragonfly/core/builder/helper/metadata_extractor.dart';
import 'package:dragonfly/core/builder/visitor/parameter_helper.dart';
import 'package:dragonfly/core/builder/visitor/return_helper.dart';

class ModelVisitor extends SimpleElementVisitor<void> {
  late String className;
  final fields = <String, dynamic>{};
  final Map<String, dynamic> metaData = {};
  final List<MethodRepositoryType> methods = [];

  @override
  void visitConstructorElement(ConstructorElement element) {
    final elementReturnType = element.type.returnType.toString();
    className = elementReturnType.replaceFirst('*', '');
  }

  @override
  void visitFieldElement(FieldElement element) {
    final elementType = element.type.toString();
    fields[element.name] = elementType.replaceFirst('*', '');
    metaData[element.name] = element.metadata;
  }

  @override
  void visitClassElement(ClassElement classElement) {}

  @override
  void visitMethodElement(MethodElement element) {
    String name = element.name;
    String path = MedatadaExtractor.getAnnotationMethodField(element, 'path');

    Map<DartObject, DartObject> headers =
        MedatadaExtractor.getAnnotationMethodField(element, 'headers');

    final String returnName =
        element.returnType.getDisplayString(withNullability: true);

    methods.add(MethodRepositoryType(
        name: name,
        params: ParameterHelper().parametersResolver(element.parameters),
        path: path,
        returnType: ReturnType(
            type: ReturnHelper().getTypeFromReturn(returnName),
            raw: returnName,
            isList: ReturnHelper().isReturnList(returnName)),
        type: MedatadaExtractor.getMethodType(element),
        headers: HeaderHelper().fromDartObject2HeaderType(headers),
        isFuture: element.isAsynchronous));
  }
}
