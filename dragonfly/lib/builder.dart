import 'package:build/build.dart';
import 'package:dragonfly/core/builder/generators/repository_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder repositoryGenerator(BuilderOptions options) =>
    SharedPartBuilder([RepositoryGenerator()], 'repositoryBuilder',
        additionalOutputExtensions: [".g"]);
