import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly/core/builder/types/method_repository_type.dart';
import 'package:dragonfly/core/builder/visitor/model_visitor.dart';
import 'package:dragonfly_annotations/annotations/repository.dart';
import 'package:source_gen/source_gen.dart';

class RepositoryGenerator extends GeneratorForAnnotation<Repository> {
  String url = '';
  String connection = '';
  bool localMethods = false;

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final visitor = ModelVisitor();

    element.visitChildren(visitor);

    final className = visitor.className;

    url = annotation.peek('path')?.stringValue ?? '';
    connection = annotation.peek('connection')?.stringValue ?? '';

    // print('---->' + jsonEncode(visitor.methods));

    // classBuffer.writeln('class _$className implements $className  {');

    for (MethodRepositoryType method in visitor.methods) {
      if (method.type == HttpAnnotations.post) {
        return buildPostMethod(className, method);
      }
    }

    return "_no_code";
  }

  String buildPostMethod(String className, MethodRepositoryType method) {
    final animal = Class((b) => b
      ..name = "_$className"
      ..implements.add(refer(className))
      // ..extend = refer('Organism')
      ..methods.add(Method((b) => b
        ..name = method.name
        ..returns = refer(method.returnType.raw)
        ..body = const Code("final ServiceLocator di = new ServiceLocator(); \n"
            "final NetworkManager network = di.get<NetworkManager>('dragonflyNetworkManager'); \n"
            ""))));

    final emitter = DartEmitter();
    return DartFormatter().format('${animal.accept(emitter)}');
  }
}
