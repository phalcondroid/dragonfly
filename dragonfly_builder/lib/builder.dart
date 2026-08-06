import 'package:build/build.dart';
import 'package:dragonfly_builder/builder/generators/factory_model_generator.dart';
import 'package:dragonfly_builder/builder/generators/form_schema_generator.dart';
import 'package:dragonfly_builder/builder/generators/injectable_config_generator.dart';
import 'package:dragonfly_builder/builder/generators/component_generator.dart';
import 'package:dragonfly_builder/builder/generators/repository_generator.dart';
import 'package:dragonfly_builder/builder/generators/state_manager_generator.dart';
import 'package:dragonfly_builder/builder/generators/state_model_generator.dart';
import 'package:dragonfly_builder/builder/generators/router_generator.dart';
import 'package:dragonfly_builder/builder/generators/view_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Builder for @Repository annotated classes.
///
/// Generates repository implementation classes with network operations.
/// Output extension: `.repository.dart`
Builder repositoryGenerator(BuilderOptions options) => PartBuilder(
      [RepositoryGenerator()],
      '.repository.dart',
      options: options,
    );

/// Builder for @FactoryModel annotated classes.
///
/// Generates model classes for repository/data layer with:
/// - fromJson factory constructor
/// - Optional toJson, toMap, equals, hashCode, toString, copyWith methods
/// - Support for generic type parameters
///
/// Output extension: `.model.dart`
Builder factoryModelGenerator(BuilderOptions options) => PartBuilder(
      [FactoryModelGenerator()],
      '.model.dart',
      options: options,
    );

/// Builder for @StateModel annotated classes.
///
/// Generates sealed state classes for BLoC-style state management with:
/// - Pattern matching methods (when, maybeWhen, map, maybeMap)
/// - Sealed subclasses for each variant
/// - Optional copyWith, toJson, toMap, equals, hashCode, toString methods
///
/// Output extension: `.state.dart`
Builder stateModelGenerator(BuilderOptions options) => PartBuilder(
      [StateModelGenerator()],
      '.state.dart',
      options: options,
    );

/// Builder for @StateManager annotated classes.
///
/// Generates a part file containing:
/// - (easy mode) the sealed state class with one variant per `@Event`
/// - the `$XController extends DragonflyController` that owns the state and
///   wraps the annotated class with auto loading/error dispatching
///
/// Output extension: `.state_manager.dart`
Builder stateManagerGenerator(BuilderOptions options) => PartBuilder(
      [StateManagerGenerator()],
      '.state_manager.dart',
      options: options,
    );

/// Builder for @StateView annotated widgets.
///
/// Generates a part file containing the `$X` view mixin that flattens event
/// dispatch and state builders onto the bound widget.
///
/// Output extension: `.view.dart`
Builder viewGenerator(BuilderOptions options) => PartBuilder(
      [ViewGenerator()],
      '.view.dart',
      options: options,
    );

/// Builder for @InjectableInit annotated classes.
///
/// Generates dependency injection configuration file.
/// Output extension: `.config.dart`
Builder injectableConfigBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableConfigGenerator(),
    generatedExtension: '.config.dart',
  );
}

/// Builder for @RouterConfig.
///
/// Generates router configuration file.
/// Output extension: `.router.dart`
Builder routerBuilder(BuilderOptions options) {
  return LibraryBuilder(
    RouterGenerator(),
    generatedExtension: '.router.dart',
  );
}

/// Builder for @FormSchema annotated classes.
///
/// Generates form state and controller classes with:
/// - FormState class to track field values, errors, and touched state
/// - FormController mixin for DragonflyController integration
/// - Field enum for type-safe field references
/// - Validation logic based on field annotations
///
/// Output extension: `.form.dart`
Builder formSchemaGenerator(BuilderOptions options) => PartBuilder(
      [FormSchemaGenerator()],
      '.form.dart',
      options: options,
    );


/// Builder for per-component barrel files.
///
/// Generates one `<component>.dragonfly.dart` per `lib/components/<name>/`
/// directory, re-exporting all generated files in the component. A single
/// import of the barrel brings in everything.
///
/// Scoped to `config/injector.dart` anchor files via `generate_for` in
/// `build.yaml`. To opt out of the barrel and import generated files
/// individually, override the builder in the consuming project's
/// `build.yaml` with `generate_for: []`.
Builder componentBuilder(BuilderOptions options) => ComponentGenerator();
