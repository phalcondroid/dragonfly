import 'package:build/build.dart';
import 'package:dragonfly/core/builder/generators/repository_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder repositoryGenerator(BuilderOptions options) => PartBuilder(
      [RepositoryGenerator()],
      formatOutput: options.config['format'] == false
          ? (str) {
              print("==========>>>> $str");
              return str;
            }
          : null,
      '.repository.dart',
      options: options,
    );
