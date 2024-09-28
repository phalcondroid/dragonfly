import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly/core/builder/types/method_repository_type.dart';
import 'package:dragonfly/core/builder/visitor/model_visitor.dart';
import 'package:dragonfly_annotations/annotations/component/repositoriy/repository.dart';
import 'package:source_gen/source_gen.dart';

class RepositoryGenerator extends GeneratorForAnnotation<Repository> {
  String url = '';
  String connection = '';
  bool localMethods = false;

  RepositoryGenerator();

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final visitor = ModelVisitor();

    element.visitChildren(visitor);

    final className = visitor.className;

    url = annotation.peek('path')?.stringValue ?? '';
    connection = annotation.peek('connection')?.stringValue ?? '';

    for (MethodRepositoryType method in visitor.methods) {
      if (method.type == HttpAnnotations.post) {
        return buildPostMethod(className, method);
      }
    }

    return "_no_code";
  }

  String _getHttpMethod(HttpAnnotations http) {
    return switch (http) {
      HttpAnnotations.post => "HttpAnnotations.post",
      HttpAnnotations.patch => "HttpAnnotations.patch",
      HttpAnnotations.put => "HttpAnnotations.put",
      HttpAnnotations.delete => "HttpAnnotations.delete",
      HttpAnnotations.get => "HttpAnnotations.get",
      _ => ""
    };
  }

  String buildPostMethod(String className, MethodRepositoryType method) {
    final methodKind = method.returnType.isList
        ? "callForComplexResultset"
        : "callForSimpleResultset";
    final String httpMethod = _getHttpMethod(method.type);
    final String returnType = method.returnType.isList
        ? "List<Map<String, Object?>>"
        : "Map<String, Object?>";

    final animal = Class((b) => b
      ..name = "_$className"
      ..implements.add(refer(className))
      // ..extend = refer('Organism')
      ..methods.add(Method((b) => b
        ..name = method.name
        ..requiredParameters
            .addAll(method.params.map((param) => Parameter((p) => p
              ..name = param.name
              ..type = refer(param.paramDataType))))
        ..modifier = MethodModifier.async
        ..annotations.add(refer('override'))
        ..returns = refer(method.returnType.raw)
        ..body = Code("final DragonflyNetworkHttpAdapter network = "
            "DragonflyInjector.get<DragonflyNetworkHttpAdapter>('__df_network_default'); \n"
            "print(network);"
            "final $returnType response = await network.$methodKind($httpMethod, '${method.path}', null, null);\n"
            "return [ ${method.returnType.modelName}(id: '', name: '', specie: '')];\n"
            ""))));

    final emitter = DartEmitter();
    return DartFormatter().format('${animal.accept(emitter)}');
  }
}
