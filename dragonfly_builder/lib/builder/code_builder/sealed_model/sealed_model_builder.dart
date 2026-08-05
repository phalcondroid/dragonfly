import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_builder/builder/code_builder/common/model_method_builder.dart';
import 'package:dragonfly_builder/builder/models/factory_model_config.dart';
import 'package:dragonfly_builder/builder/visitor/sealed_class_visitor.dart';

/// Builder for sealed class models (events and states).
///
/// This builder generates:
/// - A mixin with pattern matching methods (when, maybeWhen, map, maybeMap)
/// - Sealed subclasses for each variant
/// - Optional copyWith, equals, hashCode, toString methods
class SealedModelBuilder {
  final _formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

  /// Generates the complete code for a sealed model.
  ///
  /// [visitor] - The visitor containing parsed class information.
  /// [config] - Configuration options for code generation.
  /// [modelType] - Either 'event' or 'state' for documentation purposes.
  String generateSealedModel(
    SealedClassVisitor visitor,
    dynamic config,
    String modelType,
  ) {
    if (visitor.className == null || visitor.variants.isEmpty) {
      return '// No variants found for $modelType model';
    }

    final buffer = StringBuffer();

    // Generate the mixin with pattern matching methods
    buffer.writeln(_generateMixin(visitor, config));
    buffer.writeln();

    // Generate subclasses for each variant
    for (final variant in visitor.variants) {
      if (!variant.isDefault) {
        buffer.writeln(_generateSubclass(visitor, variant, config));
        buffer.writeln();
      }
    }

    try {
      return _formatter.format(buffer.toString());
    } catch (e) {
      return buffer.toString();
    }
  }

  /// Generates the mixin with pattern matching methods.
  String _generateMixin(SealedClassVisitor visitor, dynamic config) {
    final className = visitor.className!;
    final variants = visitor.variants.where((v) => !v.isDefault).toList();

    final mixin = cb.Mixin((m) {
      m.name = '_\$$className';

      // Add when method
      if (_shouldGenerateWhenMethods(config)) {
        m.methods.add(_buildWhenMethod(className, variants));
        m.methods.add(_buildMaybeWhenMethod(className, variants));
      }

      // Add map method
      if (_shouldGenerateMapMethods(config)) {
        m.methods.add(_buildMapMethod(className, variants));
        m.methods.add(_buildMaybeMapMethod(className, variants));
      }
    });

    final emitter = cb.DartEmitter(useNullSafetySyntax: true);
    return mixin.accept(emitter).toString();
  }

  /// Generates a subclass for a variant.
  String _generateSubclass(
    SealedClassVisitor visitor,
    SealedVariant variant,
    dynamic config,
  ) {
    final baseClassName = visitor.className!;

    final subclass = cb.Class((cls) {
      cls
        ..name = variant.className
        ..extend = cb.Reference(baseClassName)
        ..constructors.add(_buildSubclassConstructor(variant));

      // Add fields
      cls.fields.addAll(variant.parameters.map((p) => cb.Field((f) => f
        ..name = p.name
        ..modifier = cb.FieldModifier.final$
        ..type = cb.Reference(p.type))));

      // Add optional methods
      if (_shouldGenerateEquals(config)) {
        cls.methods.add(
          ModelMethodBuilder.buildEqualsOperator(variant.className, variant.parameters),
        );
        cls.methods.add(ModelMethodBuilder.buildHashCode(variant.parameters));
        
        // Add equality helpers if needed
        final hasCollection = variant.parameters.any(
          (p) => p.isDartList || p.isDartMap || p.isDartSet,
        );
        if (hasCollection) {
          cls.methods.addAll(ModelMethodBuilder.buildEqualityHelpers());
        }
      }

      if (_shouldGenerateToString(config)) {
        cls.methods.add(
          ModelMethodBuilder.buildToString(variant.className, variant.parameters),
        );
      }

      if (_shouldGenerateCopyWith(config) && variant.parameters.isNotEmpty) {
        cls.methods.add(
          ModelMethodBuilder.buildCopyWith(
            variant.className,
            variant.className,
            variant.parameters,
          ),
        );
      }
    });

    final emitter = cb.DartEmitter(useNullSafetySyntax: true);
    return subclass.accept(emitter).toString();
  }

  /// Builds the constructor for a subclass.
  cb.Constructor _buildSubclassConstructor(SealedVariant variant) {
    return cb.Constructor((c) {
      c.constant = true;

      // Add parameters
      if (variant.parameters.isEmpty) {
        // No parameters - call super()
        c.initializers.add(const cb.Code('super._()'));
      } else {
        c.initializers.add(const cb.Code('super._()'));
        c.optionalParameters.addAll(variant.parameters.map((p) => cb.Parameter((param) => param
          ..name = p.name
          ..named = true
          ..required = p.isRequired
          ..toThis = true
          ..defaultTo = p.value != null ? cb.Code(p.value.toString()) : null)));
      }
    });
  }

  /// Builds the 'when' method for pattern matching.
  ///
  /// ```dart
  /// T when<T>({
  ///   required T Function() loading,
  ///   required T Function(User user) getUser,
  /// }) { ... }
  /// ```
  cb.Method _buildWhenMethod(String baseClassName, List<SealedVariant> variants) {
    final params = variants.map((v) {
      final paramTypes = v.parameters.map((p) => '${p.type} ${p.name}').join(', ');
      final funcType = 'T Function($paramTypes)';
      return cb.Parameter((p) => p
        ..name = v.name.isEmpty ? 'default_' : v.name
        ..named = true
        ..required = true
        ..type = cb.Reference(funcType));
    }).toList();

    final switchCases = variants.map((v) {
      final variantName = v.name.isEmpty ? 'default_' : v.name;
      final args = v.parameters.map((p) => 'e.${p.name}').join(', ');
      return '${v.className} e => $variantName($args)';
    }).join(',\n      ');

    final body = '''
return switch (this) {
      $switchCases,
      _ => throw StateError('Unknown variant: \$runtimeType'),
    };
''';

    return cb.Method((m) => m
      ..name = 'when'
      ..returns = const cb.Reference('T')
      ..types.add(const cb.Reference('T'))
      ..optionalParameters.addAll(params)
      ..body = cb.Code(body));
  }

  /// Builds the 'maybeWhen' method for pattern matching with orElse fallback.
  cb.Method _buildMaybeWhenMethod(String baseClassName, List<SealedVariant> variants) {
    final params = variants.map((v) {
      final paramTypes = v.parameters.map((p) => '${p.type} ${p.name}').join(', ');
      final funcType = 'T Function($paramTypes)?';
      return cb.Parameter((p) => p
        ..name = v.name.isEmpty ? 'default_' : v.name
        ..named = true
        ..type = cb.Reference(funcType));
    }).toList();

    params.add(cb.Parameter((p) => p
      ..name = 'orElse'
      ..named = true
      ..required = true
      ..type = const cb.Reference('T Function()')));

    final switchCases = variants.map((v) {
      final variantName = v.name.isEmpty ? 'default_' : v.name;
      final args = v.parameters.map((p) => 'e.${p.name}').join(', ');
      return '${v.className} e => $variantName?.call($args) ?? orElse()';
    }).join(',\n      ');

    final body = '''
return switch (this) {
      $switchCases,
      _ => orElse(),
    };
''';

    return cb.Method((m) => m
      ..name = 'maybeWhen'
      ..returns = const cb.Reference('T')
      ..types.add(const cb.Reference('T'))
      ..optionalParameters.addAll(params)
      ..body = cb.Code(body));
  }

  /// Builds the 'map' method for type-safe pattern matching.
  cb.Method _buildMapMethod(String baseClassName, List<SealedVariant> variants) {
    final params = variants.map((v) {
      final funcType = 'T Function(${v.className} value)';
      return cb.Parameter((p) => p
        ..name = v.name.isEmpty ? 'default_' : v.name
        ..named = true
        ..required = true
        ..type = cb.Reference(funcType));
    }).toList();

    final switchCases = variants.map((v) {
      final variantName = v.name.isEmpty ? 'default_' : v.name;
      return '${v.className} e => $variantName(e)';
    }).join(',\n      ');

    final body = '''
return switch (this) {
      $switchCases,
      _ => throw StateError('Unknown variant: \$runtimeType'),
    };
''';

    return cb.Method((m) => m
      ..name = 'map'
      ..returns = const cb.Reference('T')
      ..types.add(const cb.Reference('T'))
      ..optionalParameters.addAll(params)
      ..body = cb.Code(body));
  }

  /// Builds the 'maybeMap' method for type-safe pattern matching with orElse fallback.
  cb.Method _buildMaybeMapMethod(String baseClassName, List<SealedVariant> variants) {
    final params = variants.map((v) {
      final funcType = 'T Function(${v.className} value)?';
      return cb.Parameter((p) => p
        ..name = v.name.isEmpty ? 'default_' : v.name
        ..named = true
        ..type = cb.Reference(funcType));
    }).toList();

    params.add(cb.Parameter((p) => p
      ..name = 'orElse'
      ..named = true
      ..required = true
      ..type = const cb.Reference('T Function()')));

    final switchCases = variants.map((v) {
      final variantName = v.name.isEmpty ? 'default_' : v.name;
      return '${v.className} e => $variantName?.call(e) ?? orElse()';
    }).join(',\n      ');

    final body = '''
return switch (this) {
      $switchCases,
      _ => orElse(),
    };
''';

    return cb.Method((m) => m
      ..name = 'maybeMap'
      ..returns = const cb.Reference('T')
      ..types.add(const cb.Reference('T'))
      ..optionalParameters.addAll(params)
      ..body = cb.Code(body));
  }

  // Config helper methods
  bool _shouldGenerateWhenMethods(dynamic config) {
    if (config is EventModelConfig) return config.whenMethods;
    if (config is StateModelConfig) return config.whenMethods;
    return true;
  }

  bool _shouldGenerateMapMethods(dynamic config) {
    if (config is EventModelConfig) return config.mapMethods;
    if (config is StateModelConfig) return config.mapMethods;
    return true;
  }

  bool _shouldGenerateEquals(dynamic config) {
    if (config is EventModelConfig) return config.equals;
    if (config is StateModelConfig) return config.equals;
    return true;
  }

  bool _shouldGenerateToString(dynamic config) {
    if (config is EventModelConfig) return config.toStringMethod;
    if (config is StateModelConfig) return config.toStringMethod;
    return true;
  }

  bool _shouldGenerateCopyWith(dynamic config) {
    if (config is EventModelConfig) return config.copyWith;
    if (config is StateModelConfig) return config.copyWith;
    return true;
  }
}
