import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import '../types/enums/http_annotations.dart';
import '../types/method_repository_type.dart';
import '../types/return_type.dart';
import 'header_helper.dart';
import '../helper/metadata_extractor.dart';
import 'parameter_helper.dart';
import 'return_helper.dart';

class RepositoryVisitor extends SimpleElementVisitor2<void> {
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
    fields[element.displayName] = elementType.replaceFirst('*', '');
    metaData[element.displayName] = element.metadata;
  }

  @override
  void visitClassElement(ClassElement classElement) {}

  @override
  void visitMethodElement(MethodElement element) {
    try {
      String name = element.displayName;
      final methodType = MedatadaExtractor.getMethodType(element);
      final isSubscription = methodType == HttpAnnotations.subscribe;

      String path = isSubscription
          ? ''
          : MedatadaExtractor.getAnnotationMethodField(element, 'path');

      // @Subscribe(channel:) defaults to the method name.
      String channel = '';
      if (isSubscription) {
        final declared =
            MedatadaExtractor.getAnnotationMethodField(element, 'channel');
        channel = (declared is String && declared.isNotEmpty) ? declared : name;
      }

      Map<DartObject, DartObject>? headers = isSubscription
          ? null
          : MedatadaExtractor.getAnnotationMethodField(element, 'headers');

      final String returnName =
          element.returnType.getDisplayString();

      final returnHelper = ReturnHelper();
      methods.add(MethodRepositoryType(
          name: name,
          params: ParameterHelper().parametersResolver(element.formalParameters),
          path: path,
          channel: channel,
          returnType: ReturnType(
              modelName: returnHelper.getTypeFromReturn(returnName),
              name: returnHelper.getMainClassName(returnName),
              raw: returnName,
              isList: returnHelper.isReturnList(returnName),
              isStream: returnHelper.isReturnStream(returnName),
              generics: returnHelper.extractGenerics(returnName)),
          type: methodType,
          headers: HeaderHelper().fromDartObject2HeaderType(headers),
          isFuture: false));
    } catch (e) {
      print("====>>>>>>>>> error on methods visitor ${e}");
    }
  }
}
