import 'package:dart_style/dart_style.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dragonfly_builder/builder/code_builder/factory_model/create_from_json_builder.dart';
import 'package:dragonfly_builder/builder/models/factory_model_field.dart';
import 'package:dragonfly_builder/builder/visitor/factory_model_visitor.dart';

class CommonFactoryModelBuilder {
  String createGenericModel(FactoryModelVisitor visitor,
      List<FactoryModelField> properties, bool isGeneric) {
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
          var d = cb.Field((f) => f
            ..name = p.name
            ..annotations.add(cb.Reference("override"))
            ..modifier = cb.FieldModifier.final$
            ..type = cb.Reference(p.type));
          return d;
        }))
        ..constructors.add(construct)
        ..constructors.add(CreateFromJsonBuilder()
            .fromJsonBuilder(visitor, properties, isGeneric))
        ..sealed = false;
    });

    final emitter = cb.DartEmitter();
    final String model =
        DartFormatter().format("${factoryModel.accept(emitter)}");
    return model;
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
      return "";
    }
  }
}
