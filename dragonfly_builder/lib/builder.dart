import 'package:build/build.dart';
import 'package:dragonfly_builder/builder/generators/dragonfly_bloc_generator.dart';
import 'package:dragonfly_builder/builder/generators/dragonfly_feature_generator.dart';
import 'package:dragonfly_builder/builder/generators/dragonfly_view_generator.dart';
import 'package:dragonfly_builder/builder/generators/event_model_generator.dart';
import 'package:dragonfly_builder/builder/generators/factory_model_generator.dart';
import 'package:dragonfly_builder/builder/generators/injectable_config_generator.dart';
import 'package:dragonfly_builder/builder/generators/repository_generator.dart';
import 'package:dragonfly_builder/builder/generators/state_model_generator.dart';
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

/// Builder for @EventModel annotated classes.
///
/// Generates sealed event classes for BLoC-style state management with:
/// - Pattern matching methods (when, maybeWhen, map, maybeMap)
/// - Sealed subclasses for each variant
/// - Optional equals, hashCode, toString, copyWith methods
///
/// Output extension: `.event.dart`
Builder eventModelGenerator(BuilderOptions options) => PartBuilder(
      [EventModelGenerator()],
      '.event.dart',
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

/// Builder for @DragonflyBlocAnnotation annotated classes.
///
/// Generates BLoC mixins with:
/// - Event handler registration helpers
/// - State management utilities
/// - Dispatch helpers
///
/// Output extension: `.bloc.dart`
Builder dragonflyBlocGenerator(BuilderOptions options) => PartBuilder(
      [DragonflyBlocGenerator()],
      '.bloc.dart',
      options: options,
    );

/// Builder for @DragonflyViewAnnotation annotated classes.
///
/// Generates view mixins with:
/// - State-aware widget builder methods
/// - Event dispatch helpers
/// - BLoC access utilities
/// - Standalone state builder widgets
///
/// Output extension: `.view.dart`
Builder dragonflyViewGenerator(BuilderOptions options) => PartBuilder(
      [DragonflyViewGenerator()],
      '.view.dart',
      options: options,
    );

/// Builder for @DragonflyFeature annotated classes.
///
/// Generates feature classes with:
/// - State management utilities (when, maybeWhen, map)
/// - Provider widget for auto-injection
/// - BuildContext extensions for easy access
///
/// Output extension: `.feature.dart`
Builder dragonflyFeatureGenerator(BuilderOptions options) => PartBuilder(
      [DragonflyFeatureGenerator()],
      '.feature.dart',
      options: options,
    );

/// Builder for @DragonflyInjectableInit annotated classes.
///
/// Generates dependency injection configuration file.
/// Output extension: `.config.dart`
Builder injectableConfigBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableConfigGenerator(),
    generatedExtension: '.config.dart',
  );
}
