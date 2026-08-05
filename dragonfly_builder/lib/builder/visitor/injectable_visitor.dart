import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/annotations/component/presentation/dragonfly_bloc.dart';
import 'package:dragonfly_annotations/annotations/component/presentation/feature/dragonfly_feature.dart';
import 'package:dragonfly_annotations/annotations/component/repositoriy/repository.dart';
import 'package:dragonfly_annotations/annotations/injectable/injectable_annotations.dart';
import 'package:dragonfly_builder/builder/models/dependency_config.dart';
import 'package:dragonfly_builder/builder/models/importable_type.dart';
import 'package:dragonfly_builder/builder/models/injected_dependency.dart';
import 'package:dragonfly_builder/builder/models/injectable_type.dart';
import 'package:source_gen/source_gen.dart';

/// Visitor that collects all injectable dependencies from a library
class InjectableVisitor extends SimpleElementVisitor2<void> {
  final List<DependencyConfig> dependencies = [];
  final BuildStep buildStep;

  // Type checkers for annotations
  static final _useCaseChecker = TypeChecker.typeNamed(InjectableUseCase, inPackage: 'dragonfly_annotations');
  static final _repositoryChecker = TypeChecker.typeNamed(Repository, inPackage: 'dragonfly_annotations');
  static final _blocChecker = TypeChecker.typeNamed(DragonflyBloc, inPackage: 'dragonfly_annotations');
  static final _stateManagerChecker = TypeChecker.typeNamed(DragonflyStateManager, inPackage: 'dragonfly_annotations');
  static final _injectChecker = TypeChecker.typeNamed(Inject, inPackage: 'dragonfly_annotations');
  static final _namedChecker = TypeChecker.typeNamed(Named, inPackage: 'dragonfly_annotations');

  InjectableVisitor(this.buildStep);

  @override
  void visitClassElement(ClassElement element) {
    // Skip Flutter widgets - they should not be registered in DI
    if (_isFlutterWidget(element)) {
      return;
    }

    // Check for InjectableUseCase annotation
    if (_useCaseChecker.hasAnnotationOfExact(element)) {
      _processInjectableUseCase(element);
      return;
    }

    // Check for Repository annotation
    if (_repositoryChecker.hasAnnotationOfExact(element)) {
      _processRepository(element);
      return;
    }

    // Check for DragonflyBloc annotation
    if (_blocChecker.hasAnnotationOfExact(element)) {
      _processDragonflyBloc(element);
      return;
    }

    // Check for DragonflyStateManager annotation (for Features/state managers)
    if (_stateManagerChecker.hasAnnotationOfExact(element)) {
      _processDragonflyStateManager(element);
      return;
    }
  }

  /// Check if element extends StatelessWidget or StatefulWidget
  bool _isFlutterWidget(ClassElement element) {
    for (final supertype in element.allSupertypes) {
      final name = supertype.element.name;
      if (name == 'StatelessWidget' || name == 'StatefulWidget' || name == 'Widget') {
        return true;
      }
    }
    return false;
  }

  /// Process @InjectableUseCase annotated classes
  void _processInjectableUseCase(ClassElement element) {
    final annotation =
        ConstantReader(_useCaseChecker.firstAnnotationOfExact(element));
    int injectableType = InjectableType.factory;

    // Extract annotation data
    final asType = annotation.peek('as')?.typeValue;
    final envList = annotation.peek('env')?.listValue;
    final scope = annotation.peek('scope')?.stringValue;
    final order = annotation.peek('order')?.intValue ?? 0;
    final instanceName = annotation.peek('instanceName')?.stringValue;

    // Get environments
    final environments = envList
            ?.map((e) => e.toStringValue() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    if (element.constructors.isEmpty) return;

    try {
      final constructor = element.constructors.first;

      final deps = constructor.formalParameters.map((param) {
        // Check for @Inject or @Named annotation on the parameter
        final paramInstanceName = _getParameterInstanceName(param);

        return InjectedDependency(
          type: ImportableType(
            name: param.type.getDisplayString(),
            import: param.type.element?.library?.uri.toString(),
          ),
          paramName: param.name ?? '',
          isPositional: param.isPositional,
          instanceName: paramInstanceName,
        );
      }).toList();

      // Create dependency config
      final typeImpl = ImportableType(
        name: element.name ?? '',
        import: element.library.uri.toString(),
      );

      // Extract type with all type arguments and their imports
      final type = asType != null
          ? _extractImportableType(asType)
          : typeImpl;

      final config = DependencyConfig(
        type: type,
        typeImpl: typeImpl,
        injectableType: injectableType,
        dependencies: deps,
        environments: environments,
        scope: scope,
        orderPosition: order,
        instanceName: instanceName,
      );

      dependencies.add(config);
    } catch (e, s) {
      print("==========>>>>>>>> error processing use case: $e, $s");
    }
  }

  /// Extract instance name from @Inject or @Named annotation on a parameter
  String? _getParameterInstanceName(FormalParameterElement param) {
    // Check for @Inject annotation
    if (_injectChecker.hasAnnotationOfExact(param)) {
      final injectAnnotation =
          ConstantReader(_injectChecker.firstAnnotationOfExact(param));
      return injectAnnotation.peek('name')?.stringValue;
    }

    // Check for @Named annotation
    if (_namedChecker.hasAnnotationOfExact(param)) {
      final namedAnnotation =
          ConstantReader(_namedChecker.firstAnnotationOfExact(param));
      return namedAnnotation.peek('name')?.stringValue;
    }

    return null;
  }

  /// Recursively extracts ImportableType with all type arguments and their imports
  ImportableType _extractImportableType(DartType dartType) {
    final typeName = dartType.getDisplayString();
    final element = dartType.element;
    final import = element?.library?.uri.toString();

    // Extract type arguments recursively
    final typeArguments = <ImportableType>[];
    if (dartType is InterfaceType) {
      for (final typeArg in dartType.typeArguments) {
        typeArguments.add(_extractImportableType(typeArg));
      }
    }

    return ImportableType(
      name: typeName,
      import: import,
      typeArguments: typeArguments,
    );
  }

  /// Process @Repository annotated classes
  void _processRepository(ClassElement element) {
    final annotation =
        ConstantReader(_repositoryChecker.firstAnnotationOfExact(element));

    // Extract annotation data
    final asType = annotation.peek('as')?.typeValue;
    final envList = annotation.peek('env')?.listValue;
    final scope = annotation.peek('scope')?.stringValue;
    final order = annotation.peek('order')?.intValue ?? 0;
    final instanceName = annotation.peek('instanceName')?.stringValue;

    // Get environments
    final environments = envList
            ?.map((e) => e.toStringValue() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    // Repositories are typically lazy singletons
    int injectableType = InjectableType.lazySingleton;

    try {
      // For repositories, we register the abstract class
      // The factory constructor redirects to the generated implementation
      final typeImpl = ImportableType(
        name: element.name ?? '',
        import: element.library.uri.toString(),
      );

      // Extract type with all type arguments and their imports
      final type = asType != null
          ? _extractImportableType(asType)
          : typeImpl;

      // Repositories typically don't have constructor dependencies
      // (they use the DI container internally for network adapters)
      final config = DependencyConfig(
        type: type,
        typeImpl: typeImpl,
        injectableType: injectableType,
        dependencies: [],
        environments: environments,
        scope: scope,
        orderPosition: order,
        instanceName: instanceName,
      );

      dependencies.add(config);
    } catch (e, s) {
      print("==========>>>>>>>> error processing repository: $e, $s");
    }
  }

  /// Process @DragonflyBloc annotated classes
  void _processDragonflyBloc(ClassElement element) {
    // BLoCs are registered as factories (new instance each time)
    int injectableType = InjectableType.factory;

    if (element.constructors.isEmpty) return;

    try {
      final constructor = element.constructors.first;

      // Extract constructor dependencies with @Inject support
      final deps = constructor.formalParameters.map((param) {
        final paramInstanceName = _getParameterInstanceName(param);

        return InjectedDependency(
          type: ImportableType(
            name: param.type.getDisplayString(),
            import: param.type.element?.library?.uri.toString(),
          ),
          paramName: param.name ?? '',
          isPositional: param.isPositional,
          instanceName: paramInstanceName,
        );
      }).toList();

      final typeImpl = ImportableType(
        name: element.name ?? '',
        import: element.library.uri.toString(),
      );

      final config = DependencyConfig(
        type: typeImpl,
        typeImpl: typeImpl,
        injectableType: injectableType,
        dependencies: deps,
        environments: [],
        orderPosition: 100, // BLoCs are registered after repositories and use cases
      );

      dependencies.add(config);
    } catch (e, s) {
      print("==========>>>>>>>> error processing bloc: $e, $s");
    }
  }

  /// Process @DragonflyStateManager annotated classes (StateManagers/Features)
  void _processDragonflyStateManager(ClassElement element) {
    // Only process if it extends StateManager or Feature (backwards compatibility)
    bool extendsStateManager = false;
    for (final supertype in element.allSupertypes) {
      final name = supertype.element.name;
      if (name == 'StateManager' || name == 'Feature') {
        extendsStateManager = true;
        break;
      }
    }
    if (!extendsStateManager) return;

    final annotation =
        ConstantReader(_stateManagerChecker.firstAnnotationOfExact(element));

    // Check if injectable is enabled (default: true)
    final injectable = annotation.peek('injectable')?.boolValue ?? true;
    if (!injectable) return;

    final order = annotation.peek('order')?.intValue ?? 100;
    final scope = annotation.peek('scope')?.stringValue;

    // Features are registered as factories (new instance each time)
    int injectableType = InjectableType.factory;

    if (element.constructors.isEmpty) return;

    try {
      final constructor = element.constructors.first;

      // Extract constructor dependencies with @Inject support
      final deps = constructor.formalParameters.map((param) {
        final paramInstanceName = _getParameterInstanceName(param);

        return InjectedDependency(
          type: ImportableType(
            name: param.type.getDisplayString(),
            import: param.type.element?.library?.uri.toString(),
          ),
          paramName: param.name ?? '',
          isPositional: param.isPositional,
          instanceName: paramInstanceName,
        );
      }).toList();

      final typeImpl = ImportableType(
        name: element.name ?? '',
        import: element.library.uri.toString(),
      );

      final config = DependencyConfig(
        type: typeImpl,
        typeImpl: typeImpl,
        injectableType: injectableType,
        dependencies: deps,
        environments: [],
        scope: scope,
        orderPosition: order,
      );

      dependencies.add(config);
    } catch (e, s) {
      print("==========>>>>>>>> error processing state manager: $e, $s");
    }
  }
}
