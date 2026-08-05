import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/annotations/injectable/injectable_annotations.dart';
import 'package:dragonfly_builder/builder/models/dependency_config.dart';
import 'package:dragonfly_builder/builder/models/importable_type.dart';
import 'package:dragonfly_builder/builder/models/injectable_type.dart';
import 'package:dragonfly_builder/builder/visitor/injectable_visitor.dart';
import 'package:source_gen/source_gen.dart';

import 'package:glob/glob.dart';

/// Generator that creates a .config.dart file with all dependency registrations
class InjectableConfigGenerator
    extends GeneratorForAnnotation<DragonflyInjectableInit> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final visitor = InjectableVisitor(buildStep);
    final glob = Glob('lib/**.dart');

    await for (final assetId in buildStep.findAssets(glob)) {
      try {
        final library = await buildStep.resolver.libraryFor(assetId);
        for (final element in library.classes) {
          visitor.visitClassElement(element);
        }
      } catch (e) {
        // Ignore files that can't be resolved
        continue;
      }
    }

    if (visitor.dependencies.isEmpty) {
      return '';
    }

    // Sort dependencies by order
    final sortedDeps = List<DependencyConfig>.from(visitor.dependencies)
      ..sort((a, b) => a.orderPosition.compareTo(b.orderPosition));
    return _generateConfigCode(sortedDeps);
  }

  String _generateConfigCode(List<DependencyConfig> dependencies) {
    final imports = <String>{};

    // Collect all imports (including nested type arguments)
    for (final dep in dependencies) {
      _collectImportsFromType(dep.type, imports);
      _collectImportsFromType(dep.typeImpl, imports);
      for (final param in dep.dependencies) {
        _collectImportsFromType(param.type, imports);
      }
    }

    // Build the extension class
    final extension = cb.Extension((e) => e
      ..name = 'DragonflyContainerConfigX'
      ..on = cb.refer('DragonflyContainer')
      ..methods.add(_buildConfigureMethod(dependencies)));

    final emitter = cb.DartEmitter();
    final code = StringBuffer();

    // Add header comment
    code.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    code.writeln();

    // Add imports
    code.writeln("import 'package:dragonfly/dragonfly.dart';");
    code.writeln();

    for (final import in imports) {
      if (import.startsWith('dart:') || import.startsWith('package:')) {
        code.writeln("import '$import';");
      }
    }
    code.writeln();

    // Add generated extension
    code.write(extension.accept(emitter));

    // Format the code
    try {
      return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(code.toString());
    } catch (e) {
      log.warning('Failed to format generated code: $e');
      return code.toString();
    }
  }

  /// Recursively collects imports from a type and all its type arguments
  void _collectImportsFromType(ImportableType type, Set<String> imports) {
    if (type.import != null) {
      imports.add(type.import!);
    }
    if (type.otherImports != null) {
      imports.addAll(type.otherImports!);
    }
    for (final typeArg in type.typeArguments) {
      _collectImportsFromType(typeArg, imports);
    }
  }

  cb.Method _buildConfigureMethod(List<DependencyConfig> dependencies) {
    final body = StringBuffer();
    body.writeln('final gh = DragonflyContainer.I;');
    body.writeln();

    // Group by type for better organization
    final singletons = dependencies
        .where((d) => d.injectableType == InjectableType.singleton)
        .toList();
    final lazySingletons = dependencies
        .where((d) => d.injectableType == InjectableType.lazySingleton)
        .toList();
    final factories = dependencies
        .where((d) => d.injectableType == InjectableType.factory)
        .toList();

    if (singletons.isNotEmpty) {
      body.writeln('// Singletons');
      for (final dep in singletons) {
        body.writeln(_generateRegistration(dep));
      }
      body.writeln();
    }

    if (lazySingletons.isNotEmpty) {
      body.writeln('// Lazy Singletons');
      for (final dep in lazySingletons) {
        body.writeln(_generateRegistration(dep));
      }
      body.writeln();
    }

    if (factories.isNotEmpty) {
      body.writeln('// Factories');
      for (final dep in factories) {
        body.writeln(_generateRegistration(dep));
      }
    }

    return cb.Method((m) => m
      ..name = 'configureDependencies'
      ..returns = cb.refer('Future<void>')
      ..modifier = cb.MethodModifier.async
      ..body = cb.Code(body.toString()));
  }

  String _generateRegistration(DependencyConfig dep) {
    final registerType = dep.type.name != dep.typeImpl.name
        ? '<${dep.type.name}>'
        : '<${dep.typeImpl.name}>';

    // Build constructor call with dependencies
    final params = dep.dependencies.map((d) {
      // If the dependency has an instanceName, use it in the get call
      if (d.instanceName != null && d.instanceName!.isNotEmpty) {
        return "gh.get<${d.type.name}>(instanceName: '${d.instanceName}')";
      }
      return 'gh.get<${d.type.name}>()';
    }).join(', ');

    final constructor = '${dep.typeImpl.name}($params)';

    // Build instanceName parameter if present
    final instanceNameParam =
        dep.instanceName != null && dep.instanceName!.isNotEmpty
            ? ", instanceName: '${dep.instanceName}'"
            : '';

    switch (dep.injectableType) {
      case InjectableType.singleton:
        return 'gh.registerSingleton$registerType($constructor$instanceNameParam);';
      case InjectableType.lazySingleton:
        return 'gh.registerLazySingleton$registerType(() => $constructor$instanceNameParam);';
      case InjectableType.factory:
      default:
        return 'gh.registerFactory$registerType(() => $constructor$instanceNameParam);';
    }
  }
}
