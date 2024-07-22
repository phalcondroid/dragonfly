import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
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

    element.visitChildren(
        visitor); // Visits all the children of element in no particular order.

    final className = visitor.className; // EX: 'ModelGen' for 'Model'.

    // final classBuffer = StringBuffer();

    url = annotation.peek('path')?.stringValue ?? '';
    connection = annotation.peek('connection')?.stringValue ?? '';

    print(jsonEncode(visitor.methods));

    // classBuffer.writeln('class _$className implements $className  {');

    final animal = Class((b) => b
      ..name = "_$className"
      ..implements.add(refer(className))
      // ..extend = refer('Organism')
      ..methods.add(Method.returnsVoid((b) => b
        ..name = 'eat'
        ..body = const Code("print('Yum!');"))));
    final emitter = DartEmitter();
    String code = DartFormatter().format('${animal.accept(emitter)}');

    return code;
  }
}
