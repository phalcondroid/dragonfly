import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_builder/builder/visitor/factory_model_visitor.dart';
import '../models/factory_model_field.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:source_gen/source_gen.dart';

class FactoryModelGenerator extends GeneratorForAnnotation<FactoryModel> {
  final visitor = FactoryModelVisitor();

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    element.visitChildren(visitor);

    try {
      final properties = visitor.properties;
      final bool isGeneric = annotation.peek('generic')?.boolValue ?? false;

      final construct = cb.Constructor((constructor) => constructor
        ..optionalParameters
            .addAll(properties.map((property) => cb.Parameter((p) => p
              ..name = property.name
              ..toThis = true
              ..named = true
              ..required = property.isRequired))));

      final factoryModel = cb.Class((cls) {
        if (isGeneric) {
          cls.types.add(cb.Reference(visitor.genericTypes.join(",")));
        }
        cls
          ..implements.add(const cb.Reference("FactoryModelWatcher"))
          ..name = "_\$${visitor.className}"
          ..implements.add(isGeneric
              ? cb.Reference(
                  "${visitor.className}<${visitor.genericTypes.join(",")}>")
              : cb.Reference("${visitor.className}"))
          ..fields.addAll(properties.map((p) {
            return cb.Field((f) => f
              ..name = p.name
              ..modifier = cb.FieldModifier.final$
              ..type = cb.Reference("${p.type}"));
          }))
          ..constructors.add(construct)
          ..constructors.add(fromJsonBuilder(visitor, properties, isGeneric))
          ..sealed = false;
      });

      final emitter = cb.DartEmitter();
      final String model =
          DartFormatter().format("${factoryModel.accept(emitter)}");
      final String interfaceContract =
          createAbstractInterface(visitor, properties, isGeneric);
      visitor.genericTypes = [];
      visitor.isGeneric = false;
      visitor.properties = [];
      return "$model \n $interfaceContract";
    } catch (e) {
      visitor.genericTypes = [];
      visitor.isGeneric = false;
      visitor.properties = [];
      // print("=====>>>>>> $e");
      return "";
    }
  }

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

                if (property.listTypeIsClass) {
                  item = "fromJson${property.listType}";
                }

                parsedField = """
                  JsonDatatypeMapper.mapGenericList<${property.listType}>(
                    json['$jsonKey'] as List, 
                    $item
                    )
                  """;
              }
              String genericConstructor = "";
              if (isGeneric) {
                genericConstructor =
                    "${property.type} Function(Object? json) fromJson${property.type}";
              }
              if (property.isClass) {
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
        c.requiredParameters.addAll(visitor.genericTypes.map((genType) =>
            cb.Parameter((p) => p
              ..name = "fromJson${genType.getDisplayString()}"
              ..type = cb.Reference(
                  "${genType.getDisplayString()} Function(Object? json)"))));
      }
    });
    return fromJsonConstruct;
  }

  String createAbstractInterface(
      visitor, List<FactoryModelField> properties, bool isGeneric) {
    try {
      final abstractInterface = cb.Class((c) => c
        ..abstract = true
        ..name = isGeneric
            ? "_\$${visitor.className}Contract<${visitor.genericTypes.join(",")}>"
            : "_\$${visitor.className}Contract"
        ..fields.addAll(properties.map((p) {
          return cb.Field((f) => f
            ..name = p.name
            ..type = cb.Reference("${p.type} get "));
        })));
      final emitter = cb.DartEmitter();
      return DartFormatter().format('${abstractInterface.accept(emitter)}');
    } catch (e) {
      print("=====>>>>>(types) ${visitor.genericTypes}");
      print("=====>>>>> $e");

      return "";
    }
  }
}
