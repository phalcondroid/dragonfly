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
  String realtimeConnection = '';
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
      connection =
          annotation.peek('connection')?.stringValue ?? 'defaultHttpNetwork';
      realtimeConnection = annotation.peek('realtimeConnection')?.stringValue ??
          'defaultRealtimeNetwork';

      final List<Method> methods =
          visitor.methods.map((MethodRepositoryType method) {
        final returnModelName = method.returnType.name;
        final modelMeta = modelRegistry[returnModelName];
        if (method.type == HttpAnnotations.subscribe) {
          return buildSubscriptionMethod(
              realtimeConnection, className, method, modelMeta);
        }
        return buildHttpMethod(url, connection, className, method, modelMeta);
      }).toList();

      final repository = Class((b) => b
        ..name = "_$className"
        ..implements.add(refer(className))
        // ..extend = refer('Organism')
        ..methods.addAll(methods));

      final emitter = DartEmitter();
      return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format('${repository.accept(emitter)}');
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

    // Build parameter map for logging
    final paramNames = method.params.map((p) => "'${p.name}': ${p.name}").join(', ');
    final paramsLog = method.params.isEmpty ? 'null' : '{$paramNames}';

    final Method methodBuilder = Method((b) => b
      ..name = method.name
      ..requiredParameters
          .addAll(method.params.map((param) => Parameter((p) => p
            ..name = param.name
            ..type = refer(param.paramDataType))))
      ..modifier = MethodModifier.async
      ..annotations.add(refer('override'))
      ..returns = refer(method.returnType.raw)
      ..body = Code("""
final _log = DragonflyLogManager.instance;
final _stopwatch = Stopwatch()..start();

try {
  _log.repositoryStart(
    repository: '$className',
    method: '${method.name}',
    params: $paramsLog,
  );

  final DragonflyNetworkHttpAdapter network = DragonflyContainer.I.get<DragonflyNetworkHttpAdapter>(instanceName: '$repoConn');
  final $returnType response = await network.$methodKind($httpMethod, '$repoUrl${method.path}', null, null);

  _stopwatch.stop();
  _log.repositorySuccess(
    repository: '$className',
    method: '${method.name}',
    message: 'Operation completed successfully',
    durationMs: _stopwatch.elapsedMilliseconds,
    params: $paramsLog,
  );

  $response;
} catch (e, stackTrace) {
  _stopwatch.stop();
  _log.repositoryError(
    repository: '$className',
    method: '${method.name}',
    message: 'Operation failed',
    error: e,
    stackTrace: stackTrace,
    durationMs: _stopwatch.elapsedMilliseconds,
    params: $paramsLog,
  );
  rethrow;
}
"""));

    return methodBuilder;
  }

  /// Builds a `Stream`-returning method for a `@Subscribe` annotation.
  ///
  /// Resolves a [DragonflyRealtimeAdapter] by connection name and maps each
  /// incoming JSON payload through the model's `fromJson`. Deserialization
  /// failures are surfaced as stream errors rather than killing the stream, so
  /// one malformed frame does not end the subscription.
  Method buildSubscriptionMethod(String repoRealtimeConn, String className,
      MethodRepositoryType method, FactoryModelMetadata? modelMeta) {
    final bool isList = method.returnType.isList;
    final String subscribeKind =
        isList ? 'subscribeToList' : 'subscribeToObject';
    final String eventType =
        isList ? 'List<Map<String, Object?>>' : 'Map<String, Object?>';
    final String mapping = isList
        ? buildStreamListMapping(method)
        : buildStreamObjectMapping(method);

    final paramNames = method.params.map((p) => "'${p.name}': ${p.name}").join(', ');
    final paramsArg =
        method.params.isEmpty ? 'null' : 'const <String, dynamic>{}';
    final paramsLog = method.params.isEmpty ? 'null' : '{$paramNames}';

    return Method((b) => b
      ..name = method.name
      ..requiredParameters
          .addAll(method.params.map((param) => Parameter((p) => p
            ..name = param.name
            ..type = refer(param.paramDataType))))
      ..annotations.add(refer('override'))
      ..returns = refer(method.returnType.raw)
      ..body = Code("""
final _log = DragonflyLogManager.instance;

_log.info(
  'Subscribing to ${method.channel}',
  source: '$className.${method.name}',
  data: $paramsLog,
);

final DragonflyRealtimeAdapter realtime = DragonflyContainer.I
    .get<DragonflyRealtimeAdapter>(instanceName: '$repoRealtimeConn');

return realtime.$subscribeKind('${method.channel}', params: $paramsArg)
    .map(($eventType event) {
  try {
    $mapping
  } catch (e, stackTrace) {
    _log.error(
      'Failed to deserialize a ${method.channel} event',
      error: e,
      stackTrace: stackTrace,
      source: '$className.${method.name}',
    );
    rethrow;
  }
});
"""));
  }

  /// Body of the `.map` for a `Stream<T>` subscription.
  String buildStreamObjectMapping(MethodRepositoryType method) {
    final modelName = method.returnType.modelName;

    if (method.returnType.hasGenerics) {
      final args = <String>['event'];
      for (final generic in method.returnType.generics) {
        args.add('(json) => $generic.fromJson(json as Map<String, Object?>)');
      }
      return 'return $modelName.fromJson(${args.join(", ")});';
    }
    return 'return $modelName.fromJson(event);';
  }

  /// Body of the `.map` for a `Stream<List<T>>` subscription.
  String buildStreamListMapping(MethodRepositoryType method) {
    final modelName = method.returnType.modelName;
    return 'return event.map((e) => $modelName.fromJson(e)).toList();';
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
