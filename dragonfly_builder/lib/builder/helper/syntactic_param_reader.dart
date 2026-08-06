import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

/// A factory-constructor parameter as written in source.
class SyntacticParam {
  final String name;
  final String type;
  final bool isNamed;
  final bool isRequired;
  final String? defaultValue;

  const SyntacticParam({
    required this.name,
    required this.type,
    required this.isNamed,
    required this.isRequired,
    required this.defaultValue,
  });
}

/// Reads factory-constructor parameters of a class from its **source text**.
///
/// The semantic model resolves types declared in other *generated* files to
/// `InvalidType` during a build (the producing builder and the reader run in
/// the same phase), but the source always carries the real names. Generators
/// use this as the primary source for variant field types, so a
/// `@StateModel` variant may reference e.g. a generated form state.
class SyntacticParamReader {
  /// Returns `{factoryName: [params]}` for every factory constructor of
  /// [className] declared in the library at [libraryUri]. Empty when the
  /// source cannot be read or the class is absent.
  static Future<Map<String, List<SyntacticParam>>> readFactoryParams(
    BuildStep buildStep,
    Uri libraryUri,
    String className,
  ) async {
    final assetId = _assetIdFromUri(libraryUri);
    if (assetId == null) return const {};

    final String source;
    try {
      source = await buildStep.readAsString(assetId);
    } catch (_) {
      return const {};
    }

    final unit = parseString(content: source, throwIfDiagnostics: false).unit;

    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration &&
          declaration.name.lexeme == className) {
        final result = <String, List<SyntacticParam>>{};
        for (final member in declaration.members) {
          if (member is ConstructorDeclaration &&
              member.factoryKeyword != null) {
            result[member.name?.lexeme ?? ''] =
                _paramsOf(member.parameters);
          }
        }
        return result;
      }
    }
    return const {};
  }

  static List<SyntacticParam> _paramsOf(FormalParameterList list) {
    final params = <SyntacticParam>[];

    for (final param in list.parameters) {
      final isNamed = param.isNamed;
      final isRequired = param.isRequiredNamed || param.isRequiredPositional;

      final NormalFormalParameter normal;
      final String? defaultValue;
      if (param is DefaultFormalParameter) {
        normal = param.parameter;
        defaultValue = param.defaultValue?.toString();
      } else if (param is NormalFormalParameter) {
        normal = param;
        defaultValue = null;
      } else {
        continue;
      }

      String type = 'dynamic';
      if (normal is SimpleFormalParameter) {
        type = normal.type?.toString() ?? 'dynamic';
      } else if (normal is FieldFormalParameter) {
        type = normal.type?.toString() ?? 'dynamic';
      }

      params.add(SyntacticParam(
        name: normal.name?.lexeme ?? '',
        type: type,
        isNamed: isNamed,
        isRequired: isRequired,
        defaultValue: defaultValue,
      ));
    }

    return params;
  }

  static AssetId? _assetIdFromUri(Uri uri) {
    if (uri.scheme == 'package') {
      // package:<pkg>/<path under lib/>
      final segments = uri.pathSegments;
      if (segments.length < 2) return null;
      final package = segments.first;
      final path = 'lib/${segments.skip(1).join('/')}';
      return AssetId(package, path);
    }
    if (uri.scheme == 'asset') {
      // asset:<pkg>/<path>
      final segments = uri.pathSegments;
      if (segments.length < 2) return null;
      return AssetId(segments.first, segments.skip(1).join('/'));
    }
    return null;
  }
}
