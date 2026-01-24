import 'package:dragonfly_builder/builder/models/factory_model_field.dart';
import 'package:dragonfly_builder/builder/visitor/factory_model_visitor.dart';
import 'package:code_builder/code_builder.dart' as cb;

class CreateFromJsonBuilder {
  cb.Constructor fromJsonBuilder(FactoryModelVisitor visitor,
      List<FactoryModelField> properties, bool isGeneric) {
    String finalConstructor = "_\$${visitor.className}("
        "${properties.map((property) {
              final jsonKey = property.isFieldName
                  ? property.fieldName ?? ""
                  : property.name;

              String parsedField = """
                  JsonDatatypeMapper.mapForGeneric<${property.type}>(
                    json, 
                    '$jsonKey', 
                    defaultValue: ${property.value}, 
                    mustWithDefault: ${property.value != null})
                  """;

              if (property.isDartList) {
                String item = "(item) => item";
                if (property.listTypeIsClass && isGeneric) {
                  item = "fromJson${property.listType}";
                } else if (property.listTypeIsClass && !isGeneric) {
                  item =
                      "(e) => ${property.listType}.fromJson(e as Map<String, Object?>)";
                }

                parsedField = """
                  JsonDatatypeMapper.mapGenericList<${property.listType}>(
                    json['$jsonKey'] as List, 
                    $item
                    )
                  """;
              }
              String genericConstructor = "";
              if (isGeneric && !property.isDartList) {
                parsedField = """
                  JsonDatatypeMapper.mapForGeneric<${property.type}>(
                    json, 
                    '$jsonKey', 
                    defaultValue: ${property.value}, 
                    mustWithDefault: ${property.value != null})
                """;
              }
              if (property.isClass && !isGeneric) {
                parsedField =
                    "${property.type}.fromJson(json['$jsonKey'] as Map<String, Object?>, $genericConstructor)";
              }
              return "${property.name}: $parsedField";
            }).toList().join(",")}"
        "); ";
    final String body = "return $finalConstructor";
    final fromJsonConstruct = cb.Constructor((c) {
      c
        ..factory = true
        ..requiredParameters.add(cb.Parameter((p) => p
          ..name = "json"
          ..type = const cb.Reference("Map<String, Object?>")))
        ..body = cb.Code(body)
        ..name = "fromJson";
      if (isGeneric) {
        c.requiredParameters.addAll(visitor.genericTypes.map((genType) {
          // print("===>>>> la super property ${genType}");
          return cb.Parameter((p) => p
            ..name =
                "fromJson${genType.getDisplayString(withNullability: true)}"
            ..type = cb.Reference(
                "${genType.getDisplayString(withNullability: true)} Function(Object? json)"));
        }));
      }
    });
    return fromJsonConstruct;
  }
}
