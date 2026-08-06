import 'package:analyzer/dart/element/element.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/types/enums/params_annotations.dart';
import 'package:dragonfly_builder/builder/types/params_type.dart';
import 'package:source_gen/source_gen.dart';

/// Resolves repository method parameters into [ParamsType], classifying each
/// by its binding annotation: `@Path`, `@Query`, `@Body` or `@Header`.
///
/// Unannotated parameters are classified [ParamsAnnotations.none]; the
/// repository generator binds those as query parameters by default.
class ParameterHelper {
  static final _pathChecker =
      TypeChecker.typeNamed(Path, inPackage: 'dragonfly_annotations');
  static final _queryChecker =
      TypeChecker.typeNamed(Query, inPackage: 'dragonfly_annotations');
  static final _bodyChecker =
      TypeChecker.typeNamed(Body, inPackage: 'dragonfly_annotations');
  static final _headerChecker =
      TypeChecker.typeNamed(Header, inPackage: 'dragonfly_annotations');

  List<ParamsType> parametersResolver(List<FormalParameterElement> parameters) {
    return parameters.map(_resolve).toList();
  }

  ParamsType _resolve(FormalParameterElement param) {
    final name = param.name ?? '';
    final dataType = param.type.getDisplayString();

    if (_pathChecker.hasAnnotationOfExact(param)) {
      return ParamsType(
        name: name,
        value: _placeholderName(_pathChecker, param, name),
        paramDataType: dataType,
        type: ParamsAnnotations.path,
        valueType: ValueType.simple,
      );
    }

    if (_queryChecker.hasAnnotationOfExact(param)) {
      return ParamsType(
        name: name,
        value: _placeholderName(_queryChecker, param, name),
        paramDataType: dataType,
        type: ParamsAnnotations.query,
        valueType: ValueType.simple,
      );
    }

    if (_bodyChecker.hasAnnotationOfExact(param)) {
      return ParamsType(
        name: name,
        value: name,
        paramDataType: dataType,
        type: ParamsAnnotations.body,
        valueType: ValueType.simple,
      );
    }

    if (_headerChecker.hasAnnotationOfExact(param)) {
      final annotation = _headerChecker.firstAnnotationOfExact(param);
      final items = <String, String>{};
      ConstantReader(annotation).peek('item')?.mapValue.forEach((k, v) {
        final key = k?.toStringValue();
        final value = v?.toStringValue();
        if (key != null && value != null) items[key] = value;
      });
      return ParamsType(
        name: name,
        value: name,
        paramDataType: dataType,
        type: ParamsAnnotations.header,
        valueType: ValueType.simple,
        headerItems: items,
      );
    }

    return ParamsType(
      name: name,
      value: name,
      paramDataType: dataType,
      type: ParamsAnnotations.none,
      valueType: ValueType.simple,
    );
  }

  /// Reads the annotation's `value`, falling back to the parameter name when
  /// empty (`@Path() int id` binds the `{id}` placeholder).
  String _placeholderName(
      TypeChecker checker, FormalParameterElement param, String fallback) {
    final annotation = checker.firstAnnotationOfExact(param);
    if (annotation == null) return fallback;
    final value = ConstantReader(annotation).peek('value')?.stringValue;
    return (value == null || value.isEmpty) ? fallback : value;
  }
}
