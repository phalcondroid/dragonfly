import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import '../types/method_repository_type.dart';
import '../helper/metadata_extractor.dart';

class UseCaseVisitor extends SimpleElementVisitor<void> {
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
  void visitFieldElement(FieldElement element) {}

  @override
  void visitClassElement(ClassElement classElement) {}

  @override
  void visitMethodElement(MethodElement element) {
    String name = element.displayName;
    String path = MedatadaExtractor.getAnnotationMethodField(element, 'path');
  }
}
