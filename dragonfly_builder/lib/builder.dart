import 'package:build/build.dart';
import 'package:dragonfly_builder/builder/generators/factory_model_generator.dart';
import 'package:dragonfly_builder/builder/generators/injectable_config_generator.dart';
import 'package:dragonfly_builder/builder/generators/repository_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder repositoryGenerator(BuilderOptions options) => PartBuilder(
      [RepositoryGenerator()],
      '.repository.dart',
      options: options,
    );

Builder factoryModelGenerator(BuilderOptions options) => PartBuilder(
      [FactoryModelGenerator()],
      '.model.dart',
      options: options,
    );

Builder injectableConfigBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableConfigGenerator(),
    generatedExtension: '.config.dart',
  );
}
