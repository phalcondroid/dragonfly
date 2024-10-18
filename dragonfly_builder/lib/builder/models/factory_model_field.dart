import 'package:analyzer/dart/element/type.dart';

class FactoryModelField {
  final String name;
  final String? fieldName;
  final bool isFieldName;
  final Object? value;
  final String type;
  final bool isNullable;
  final bool isDartList;
  final bool isDartMap;
  final bool isDartSet;
  final bool isRequired;
  final bool isClass;
  final bool isFinal;
  final DartType rawType;
  final String listType;
  final bool listTypeIsClass;

  const FactoryModelField(
      {required this.name,
      required this.fieldName,
      required this.isFieldName,
      this.value,
      required this.type,
      required this.isDartList,
      required this.isDartMap,
      required this.isDartSet,
      required this.isFinal,
      required this.isNullable,
      required this.isClass,
      required this.isRequired,
      required this.rawType,
      required this.listType,
      required this.listTypeIsClass});
}

class FactoryModelData {
  final String modelName;
  final List<FactoryModelField> fields;
  const FactoryModelData({required this.modelName, required this.fields});
}
