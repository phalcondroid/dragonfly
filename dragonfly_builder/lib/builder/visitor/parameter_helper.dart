import 'package:analyzer/dart/element/element.dart';
import 'package:dragonfly_builder/builder/types/enums/params_annotations.dart';
import 'package:dragonfly_builder/builder/types/params_type.dart';

/// Resolves repository method parameters into [ParamsType].
///
/// This previously read `metadata.annotations.first` unconditionally, which
/// threw `Bad state: No element` for any unannotated parameter — and because
/// `RepositoryVisitor.visitMethodElement` swallows exceptions, the whole method
/// then vanished from the generated repository with no error. Unannotated
/// parameters are now tolerated.
class ParameterHelper {
  List<ParamsType> parametersResolver(
      List<FormalParameterElement> parameters) {
    final params = <ParamsType>[];

    for (final param in parameters) {
      final annotations = param.metadata.annotations;
      final source = annotations.isEmpty ? '' : annotations.first.toString();

      params.add(ParamsType(
        name: param.displayName,
        paramDataType: '${param.type}',
        value: source.isEmpty ? '' : source.split(' ').first,
        type: _classify(source),
        valueType: ValueType.simple,
      ));
    }

    return params;
  }

  /// Maps a parameter's annotation to its binding kind.
  ///
  /// Nothing downstream consumes this yet — the repository generator still
  /// passes `null` for params and body. See docs/ai/known-gaps.md #2.
  ParamsAnnotations _classify(String source) {
    if (source.contains('@Query')) return ParamsAnnotations.query;
    return ParamsAnnotations.path;
  }
}
