import 'package:dart_style/dart_style.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dragonfly_builder/builder/code_builder/factory_model/create_from_json_builder.dart';
import 'package:dragonfly_builder/builder/code_builder/common/model_method_builder.dart';
import 'package:dragonfly_builder/builder/models/factory_model_field.dart';
import 'package:dragonfly_builder/builder/models/factory_model_config.dart';
import 'package:dragonfly_builder/builder/visitor/factory_model_visitor.dart';

/// Builder for creating factory model classes.
class CommonFactoryModelBuilder {
  final _formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

  /// Creates the generated model class.
  ///
  /// Example output:
  /// ```dart
  /// class _$User implements FactoryModelWatcher, User {
  ///   _$User({required this.name, required this.age});
  ///
  ///   factory _$User.fromJson(Map<String, Object?> json) { ... }
  ///
  ///   @override
  ///   final String name;
  ///
  ///   @override
  ///   final int age;
  ///
  ///   // Optional: toJson, toMap, equals, hashCode, toString, copyWith
  /// }
  /// ```
  String createGenericModel(
    FactoryModelVisitor visitor,
    List<FactoryModelField> properties,
    FactoryModelConfig config,
  ) {
    final genericTypeNames = visitor.genericTypes
        .map((t) => t.getDisplayString())
        .toList();

    final genericSuffix = config.isGeneric && genericTypeNames.isNotEmpty
        ? '<${genericTypeNames.join(', ')}>'
        : '';

    final factoryModel = cb.Class((cls) {
      // Add generic type parameters
      if (config.isGeneric && visitor.genericTypes.isNotEmpty) {
        cls.types.addAll(
          visitor.genericTypes.map(
            (t) => cb.Reference(t.getDisplayString()),
          ),
        );
      }

      cls
        ..name = '_\$${visitor.className}'
        ..implements.add(const cb.Reference('FactoryModelWatcher'))
        ..implements.add(cb.Reference('${visitor.className}$genericSuffix'));

      // @AggregateRoot: implement AggregateRoot<identityType> contract
      String? aggregateIdType;
      if (config.aggregateRoot != null) {
        final idField = properties.cast<FactoryModelField?>().firstWhere(
          (p) => p!.name == config.aggregateRoot,
          orElse: () => null,
        );
        aggregateIdType = idField?.type ?? 'Object';
        cls.implements.add(cb.Reference('AggregateRoot<$aggregateIdType>'));
      }

      cls
        // Add fields
        ..fields.addAll(_buildFields(properties))
        // Add constructor
        ..constructors.add(_buildConstructor(properties))
        // Add fromJson factory
        ..constructors.add(
          CreateFromJsonBuilder()
              .fromJsonBuilder(visitor, properties, config.isGeneric),
        );

      // Add optional methods based on config
      _addOptionalMethods(
        cls,
        visitor.className!,
        '_\$${visitor.className}',
        properties,
        config,
        genericTypeNames,
        aggregateIdType: aggregateIdType,
      );
    });

    final emitter = cb.DartEmitter(useNullSafetySyntax: true);
    try {
      return _formatter.format('${factoryModel.accept(emitter)}');
    } catch (e) {
      return '${factoryModel.accept(emitter)}';
    }
  }

  /// Creates the abstract interface contract class.
  ///
  /// This includes:
  /// - Getter signatures for all properties
  /// - Method signatures for toJson, toMap, copyWith (if enabled)
  String createAbstractInterface(
    FactoryModelVisitor visitor,
    List<FactoryModelField> properties,
    FactoryModelConfig config,
  ) {
    final genericTypeNames = visitor.genericTypes
        .map((t) => t.getDisplayString())
        .toList();

    final genericSuffix = config.isGeneric && genericTypeNames.isNotEmpty
        ? '<${genericTypeNames.join(', ')}>'
        : '';

    try {
      final abstractInterface = cb.Class((c) {
        c
          ..abstract = true
          ..name = '_\$${visitor.className}Contract$genericSuffix'
          ..fields.addAll(properties.map((p) {
            return cb.Field((f) => f
              ..name = p.name
              ..type = cb.Reference('${p.type} get '));
          }));

        // Add method signatures to the contract
        // For generic models, these methods have different signatures (with function params)
        // so we only add them for non-generic models
        if (!config.isGeneric) {
          if (config.toJson) {
            c.methods.add(cb.Method((m) => m
              ..name = 'toJson'
              ..returns = const cb.Reference('Map<String, dynamic>')));
          }

          if (config.toMap) {
            c.methods.add(cb.Method((m) => m
              ..name = 'toMap'
              ..returns = const cb.Reference('Map<String, Object?>')));
          }

          if (config.copyWith) {
            final params = properties.map((p) {
              String type = p.type;
              if (!type.endsWith('?')) {
                type = '$type?';
              }
              return cb.Parameter((param) => param
                ..name = p.name
                ..named = true
                ..type = cb.Reference(type));
            }).toList();

            c.methods.add(cb.Method((m) => m
              ..name = 'copyWith'
              ..returns = cb.Reference('${visitor.className}$genericSuffix')
              ..optionalParameters.addAll(params)));
          }
        }
      });

      final emitter = cb.DartEmitter(useNullSafetySyntax: true);
      return _formatter.format('${abstractInterface.accept(emitter)}');
    } catch (e) {
      return '';
    }
  }

  /// Builds the class fields.
  Iterable<cb.Field> _buildFields(List<FactoryModelField> properties) {
    return properties.map((p) {
      return cb.Field((f) => f
        ..name = p.name
        ..annotations.add(const cb.Reference('override'))
        ..modifier = cb.FieldModifier.final$
        ..type = cb.Reference(p.type));
    });
  }

  /// Builds the default constructor.
  cb.Constructor _buildConstructor(List<FactoryModelField> properties) {
    return cb.Constructor(
        (constructor) => constructor.optionalParameters.addAll(
              properties.map((property) => cb.Parameter((p) => p
                ..name = property.name
                ..toThis = true
                ..named = true
                ..required = property.isRequired)),
            ));
  }

  /// Adds optional methods based on configuration.
  void _addOptionalMethods(
    cb.ClassBuilder cls,
    String className,
    String generatedClassName,
    List<FactoryModelField> properties,
    FactoryModelConfig config,
    List<String> genericTypes, {
    String? aggregateIdType,
  }) {
    // Add toJson method
    if (config.toJson) {
      cls.methods.add(ModelMethodBuilder.buildToJson(
        properties,
        isGeneric: config.isGeneric,
        genericTypes: genericTypes,
      ));
    }

    // Add toMap method
    if (config.toMap) {
      cls.methods.add(ModelMethodBuilder.buildToMap(
        properties,
        isGeneric: config.isGeneric,
        genericTypes: genericTypes,
      ));
    }

    // Add equality operator and hashCode
    if (config.equals) {
      if (config.aggregateRoot != null) {
        // Identity-based equality — only the @AggregateRoot's identity field
        cls.methods.add(_buildIdentityEquals(config.aggregateRoot!, className));
        cls.methods.add(_buildIdentityHashCode(config.aggregateRoot!));
        cls.methods.add(_buildSameIdentityAs(config.aggregateRoot!, className));
        cls.methods.add(_buildIsNew(config.aggregateRoot!));
        cls.methods.add(_buildIdentityGetter(config.aggregateRoot!, aggregateIdType!));
      } else {
        cls.methods
            .add(ModelMethodBuilder.buildEqualsOperator(className, properties));
        cls.methods.add(ModelMethodBuilder.buildHashCode(properties));
      }
    }

    // Add toString method
    if (config.toStringMethod) {
      cls.methods.add(ModelMethodBuilder.buildToString(className, properties));
    }

    // Add copyWith method
    if (config.copyWith) {
      cls.methods.add(ModelMethodBuilder.buildCopyWith(
        className,
        generatedClassName,
        properties,
        isGeneric: config.isGeneric,
        genericTypes: genericTypes,
      ));
    }

    // Add equality helper methods if needed
    if (config.equals) {
      final hasCollection =
          properties.any((p) => p.isDartList || p.isDartMap || p.isDartSet);
      if (hasCollection) {
        cls.methods.addAll(ModelMethodBuilder.buildEqualityHelpers());
      }
    }
  }

  /// Identity-based `==` — two aggregates are equal when their identity
  /// field matches, regardless of other state.
  cb.Method _buildIdentityEquals(String idField, String className) {
    return cb.Method((m) => m
      ..annotations.add(const cb.Reference('override'))
      ..name = 'operator =='
      ..returns = cb.refer('bool')
      ..requiredParameters.add(cb.Parameter((p) => p
        ..name = 'other'
        ..type = const cb.Reference('Object')))
      ..lambda = false
      ..body = cb.Block.of([
        cb.Code('return identical(this, other) ||'),
        cb.Code('    other is $className && $idField == other.$idField;'),
      ]));
  }

  /// Identity-based `hashCode` — only the identity field.
  cb.Method _buildIdentityHashCode(String idField) {
    return cb.Method((m) => m
      ..annotations.add(const cb.Reference('override'))
      ..name = 'hashCode'
      ..type = cb.MethodType.getter
      ..returns = cb.refer('int')
      ..lambda = true
      ..body = cb.Code('$idField.hashCode'));
  }

  /// `sameIdentityAs` — identity comparison.
  cb.Method _buildSameIdentityAs(String idField, String className) {
    return cb.Method((m) => m
      ..annotations.add(const cb.Reference('override'))
      ..name = 'sameIdentityAs'
      ..returns = cb.refer('bool')
      ..requiredParameters.add(cb.Parameter((p) => p
        ..name = 'other'
        ..type = const cb.Reference('Object')))
      ..lambda = true
      ..body = cb.Code('other is $className && $idField == other.$idField'));
  }

  /// `isNew` getter — true before persistence.
  cb.Method _buildIsNew(String idField) {
    return cb.Method((m) => m
      ..annotations.add(const cb.Reference('override'))
      ..name = 'isNew'
      ..type = cb.MethodType.getter
      ..returns = cb.refer('bool')
      ..lambda = true
      ..body = cb.Code('$idField == null'));
  }

  /// `identity` getter — returns the aggregate's unique identifier.
  cb.Method _buildIdentityGetter(String idField, String idType) {
    return cb.Method((m) => m
      ..annotations.add(const cb.Reference('override'))
      ..name = 'identity'
      ..type = cb.MethodType.getter
      ..returns = cb.refer(idType)
      ..lambda = true
      ..body = cb.Code(idField));
  }
}
