import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/annotations/component/repositoriy/repository.dart';
import 'package:dragonfly_builder/builder/helper/factory_model_registry.dart';
import 'package:dragonfly_builder/builder/models/factory_model_metadata.dart';
import 'package:dragonfly_builder/builder/types/enums/http_annotations.dart';
import 'package:dragonfly_builder/builder/types/method_repository_type.dart';
import 'package:dragonfly_builder/builder/visitor/repository_visitor.dart';
import 'package:source_gen/source_gen.dart';

class RepositoryGenerator extends GeneratorForAnnotation<Repository> {
  String url = '';
  String connection = '';
  bool localMethods = false;

  RepositoryGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    try {
      // Collect factory model metadata from all @FactoryModel annotated classes
      final modelRegistry =
          await FactoryModelRegistry.collectMetadata(buildStep);

      final visitor = RepositoryVisitor();

      element.visitChildren(visitor);

      final className = visitor.className;

      url = annotation.peek('url')?.stringValue ?? '';
      connection = annotation.peek('connection')?.stringValue ?? '';

      final List<Method> methods =
          visitor.methods.map((MethodRepositoryType method) {
        final returnModelName = method.returnType.name;
        final modelMeta = modelRegistry[returnModelName];
        return buildHttpMethod(url, connection, className, method, modelMeta);
      }).toList();

      final repository = Class((b) => b
        ..name = "_$className"
        ..implements.add(refer(className))
        // ..extend = refer('Organism')
        ..methods.addAll(methods));

      final emitter = DartEmitter();
      return DartFormatter().format('${repository.accept(emitter)}');
    } catch (e) {
      print("====>>>>>>>>> error on repository generator ${e}");
      return "";
    }
  }

  String _getHttpMethod(HttpAnnotations http) {
    return switch (http) {
      HttpAnnotations.post => "HttpMethods.post",
      HttpAnnotations.patch => "HttpMethods.patch",
      HttpAnnotations.put => "HttpMethods.put",
      HttpAnnotations.delete => "HttpMethods.delete",
      HttpAnnotations.get => "HttpMethods.get",
      _ => ""
    };
  }

  Method buildHttpMethod(String repoUrl, String repoConn, String className,
      MethodRepositoryType method, FactoryModelMetadata? modelMeta) {
    final methodKind =
        method.returnType.isList ? "callForList" : "callForObject";
    final bool isList = method.returnType.isList;
    final String httpMethod = _getHttpMethod(method.type);
    final String returnType = method.returnType.isList
        ? "List<Map<String, Object?>>"
        : "Map<String, Object?>";

    final String response = isList
        ? buildResponseWhenIsList(method, modelMeta)
        : buildResponseWhenIsObject(method, modelMeta);

    final Method methodBuilder = Method((b) => b
      ..name = method.name
      ..requiredParameters
          .addAll(method.params.map((param) => Parameter((p) => p
            ..name = param.name
            ..type = refer(param.paramDataType))))
      ..modifier = MethodModifier.async
      ..annotations.add(refer('override'))
      ..returns = refer(method.returnType.raw)
      ..body = Code("final DragonflyNetworkHttpAdapter network = "
          "DragonflyContainer().get<DragonflyNetworkHttpAdapter>(instanceName: '__http__$repoConn'); \n"
          "final $returnType response = await network.$methodKind($httpMethod, '$repoUrl${method.path}', null, null);\n"
          "$response;\n"
          ""));

    return methodBuilder;
  }

  String buildResponseWhenIsList(
      MethodRepositoryType method, FactoryModelMetadata? modelMeta) {
    String modelName = method.returnType.modelName;
    return "return response.map((e) => $modelName.fromJson(e))";
  }

  String buildResponseWhenIsObject(
      MethodRepositoryType method, FactoryModelMetadata? modelMeta) {
    String modelName = method.returnType.modelName;

    if (method.returnType.hasGenerics) {
      List<String> generics = ["response as Map<String, Object?>"];
      for (String generic in method.returnType.generics) {
        generics
            .add("(json) => $generic.fromJson(json as Map<String, Object?>)");
      }
      return "return $modelName.fromJson(${generics.join(", ")})";
    }
    return "return $modelName.fromJson(response as Map<String, Object?>)";
  }
}
