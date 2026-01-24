import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/annotations/component/repositoriy/repository.dart';
import 'package:dragonfly_annotations/annotations/injectable/injectable_annotations.dart';
import 'package:dragonfly_builder/builder/models/dependency_config.dart';
import 'package:dragonfly_builder/builder/models/importable_type.dart';
import 'package:dragonfly_builder/builder/models/injected_dependency.dart';
import 'package:dragonfly_builder/builder/models/injectable_type.dart';
import 'package:source_gen/source_gen.dart';

/// Visitor that collects all injectable dependencies from a library
class InjectableVisitor extends SimpleElementVisitor<void> {
  final List<DependencyConfig> dependencies = [];
  final BuildStep buildStep;

  // Type checkers for annotations
  static final _useCaseChecker = TypeChecker.fromRuntime(InjectableUseCase);
  static final _repositoryChecker = TypeChecker.fromRuntime(Repository);

  InjectableVisitor(this.buildStep);

  @override
  void visitClassElement(ClassElement element) {
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

    // Get environments
    final environments = envList
            ?.map((e) => e.toStringValue() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    if (element.constructors.isEmpty) return;

    try {
      final constructor = element.constructors.first;

      final deps = constructor.parameters.map((param) {
        return InjectedDependency(
          type: ImportableType(
            name: param.type.getDisplayString(withNullability: false),
            import: param.type.element?.librarySource?.uri.toString(),
          ),
          paramName: param.name,
          isPositional: param.isPositional,
        );
      }).toList();

      // Create dependency config
      final typeImpl = ImportableType(
        name: element.name,
        import: element.librarySource.uri.toString(),
      );

      final type = asType != null
          ? ImportableType(
              name: asType.getDisplayString(withNullability: false),
              import: asType.element?.librarySource?.uri.toString(),
            )
          : typeImpl;

      final config = DependencyConfig(
        type: type,
        typeImpl: typeImpl,
        injectableType: injectableType,
        dependencies: deps,
        environments: environments,
        scope: scope,
        orderPosition: order,
      );

      dependencies.add(config);
    } catch (e, s) {
      print("==========>>>>>>>> error processing use case: $e, $s");
    }
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
        name: element.name,
        import: element.librarySource.uri.toString(),
      );

      final type = asType != null
          ? ImportableType(
              name: asType.getDisplayString(withNullability: false),
              import: asType.element?.librarySource?.uri.toString(),
            )
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
      );

      dependencies.add(config);
    } catch (e, s) {
      print("==========>>>>>>>> error processing repository: $e, $s");
    }
  }
}
