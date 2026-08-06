import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';

/// Produces one `*.dragonfly.dart` barrel per component directory that
/// re-exports every source file (models, states, state managers, views,
/// repositories, forms) whose generated parts live in the component.
///
/// A single `import 'injector.dragonfly.dart'` from the injector pulls in
/// the entire component's public API surface.
///
/// Runs only on `config/injector.dart` anchor files so there is exactly one
/// barrel per component, placed next to the injector.
///
/// Consumers that prefer to import generated files individually simply omit
/// this builder from their `build.yaml` — the per-file `PartBuilder`
/// generators remain active and independent.
class ComponentGenerator extends Builder {
  final _formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.dragonfly.dart'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    if (!inputId.path.endsWith('config/injector.dart')) return;

    final parts = inputId.pathSegments;
    final componentIndex = parts.indexOf('components') + 1;
    if (componentIndex <= 0 || componentIndex >= parts.length) return;
    final componentName = parts[componentIndex];
    final rootSegments = parts.sublist(0, componentIndex + 1);

    final exports = <String>{};

    await for (final assetId
        in buildStep.findAssets(Glob('${rootSegments.join('/')}/**.dart'))) {
      if (!_isGeneratedFile(assetId.path)) continue;

      final sourcePath = _sourcePath(assetId.path);
      if (sourcePath != null) {
        exports.add("export 'package:${inputId.package}/${sourcePath.substring(4)}';");
      }
    }

    if (exports.isEmpty) return;

    final outputId = inputId.changeExtension('.dragonfly.dart');

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE — $componentName component barrel');
    buffer.writeln();
    buffer.writeln('// Import this single file instead of the individual generated');
    buffer.writeln('// .model.dart, .state.dart, .state_manager.dart, .view.dart,');
    buffer.writeln('// .repository.dart and .form.dart files.');
    buffer.writeln();
    buffer.writeln('// sdc: ignore_for_file avoid_empty_blocks let_bloc_propagate');
    buffer.writeln();
    for (final export in (exports.toList()..sort())) {
      buffer.writeln(export);
    }

    await buildStep.writeAsString(outputId, _formatter.format(buffer.toString()));
  }

  bool _isGeneratedFile(String path) {
    if (path.contains('/screens/')) return false;
    return path.contains('.model.dart') ||
        (path.contains('.state.dart') && !path.contains('.state_manager.dart')) ||
        path.contains('.state_manager.dart') ||
        path.contains('.view.dart') ||
        path.contains('.repository.dart') ||
        path.contains('.form.dart');
  }

  String? _sourcePath(String path) {
    for (final suffix in [
      '.model.dart',
      '.state.dart',
      '.state_manager.dart',
      '.view.dart',
      '.repository.dart',
      '.form.dart',
    ]) {
      if (path.endsWith(suffix)) {
        return path.substring(0, path.length - suffix.length) + '.dart';
      }
    }
    return null;
  }
}

Builder componentBuilder(BuilderOptions options) => ComponentGenerator();
