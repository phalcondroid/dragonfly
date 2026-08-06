import 'package:dragonfly_builder/builder/types/blank_type.dart';
import 'package:dragonfly_builder/builder/types/enums/params_annotations.dart';

enum ValueType { simple, list }

class ParamsType extends BlankType {
  final ParamsAnnotations type;
  final String paramDataType;
  final ValueType valueType;
  final List<Map<String, String>>? valueAsList;

  /// Static header entries from `@Header(item:)`; only set when
  /// [type] is [ParamsAnnotations.header].
  final Map<String, String>? headerItems;

  const ParamsType(
      {required super.name,
      required super.value,
      required this.paramDataType,
      required this.type,
      required this.valueType,
      this.valueAsList,
      this.headerItems});
}
