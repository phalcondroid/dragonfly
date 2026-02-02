import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @DragonflyFeature annotated classes.
///
/// This generator creates:
/// - A mixin with helper methods for the feature
/// - A typed `when` method for state handling
/// - A provider widget for easy injection
/// - Registration in DI if injectable is true
///
/// Example input:
/// ```dart
/// @DragonflyFeature()
/// class CharacterFeature extends Feature<CharacterState> {
///   @InitialState()
///   CharacterState get initialState => const CharacterState.initial();
///
///   @Intent()
///   Future<void> fetchCharacter(int id) async { ... }
/// }
/// ```
class DragonflyFeatureGenerator
    extends GeneratorForAnnotation<DragonflyFeature> {
  final _formatter = DartFormatter();

  static final _actionChecker = TypeChecker.fromRuntime(FeatureAction);
  static final _computedChecker = TypeChecker.fromRuntime(Computed);
  static final _initialStateChecker = TypeChecker.fromRuntime(InitialState);

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@DragonflyFeature can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final logging = annotation.read('logging').boolValue;
    final injectable = annotation.read('injectable').boolValue;

    // Find the state type from the superclass
    final stateType = _extractStateType(element);

    // Extract intents
    final intents = _extractIntents(element);

    // Extract computed properties
    final computedProps = _extractComputedProperties(element);

    // Find state variants if state type is a sealed class
    final stateVariants = await _findStateVariants(buildStep, stateType);

    try {
      final code = _generateFeatureCode(
        className: className,
        stateType: stateType,
        logging: logging,
        injectable: injectable,
        intents: intents,
        computedProps: computedProps,
        stateVariants: stateVariants,
      );

      return _formatter.format(code);
    } catch (e, stackTrace) {
      log.severe('DragonflyFeatureGenerator error: $e\n$stackTrace');
      return '// Error generating feature code: $e';
    }
  }

  String _extractStateType(ClassElement element) {
    // Look for Feature<S> in supertype
    for (final supertype in element.allSupertypes) {
      if (supertype.element.name == 'Feature') {
        final typeArgs = supertype.typeArguments;
        if (typeArgs.isNotEmpty) {
          return typeArgs.first.getDisplayString(withNullability: false);
        }
      }
    }

    // Fallback: try to infer from initialState getter
    for (final accessor in element.accessors) {
      if (_initialStateChecker.hasAnnotationOfExact(accessor)) {
        return accessor.returnType.getDisplayString(withNullability: false);
      }
    }

    return 'dynamic';
  }

  List<_IntentInfo> _extractIntents(ClassElement element) {
    final intents = <_IntentInfo>[];

    for (final method in element.methods) {
      if (_actionChecker.hasAnnotationOfExact(method)) {
        final annotation =
            ConstantReader(_actionChecker.firstAnnotationOfExact(method));

        final debounce = annotation.peek('debounce');
        final throttle = annotation.peek('throttle');
        final log = annotation.peek('log')?.boolValue ?? true;

        Duration? debounceDuration;
        Duration? throttleDuration;

        if (debounce != null && !debounce.isNull) {
          final microseconds =
              debounce.objectValue.getField('_duration')?.toIntValue();
          if (microseconds != null) {
            debounceDuration = Duration(microseconds: microseconds);
          }
        }

        if (throttle != null && !throttle.isNull) {
          final microseconds =
              throttle.objectValue.getField('_duration')?.toIntValue();
          if (microseconds != null) {
            throttleDuration = Duration(microseconds: microseconds);
          }
        }

        final params = method.parameters.map((p) {
          return _ParamInfo(
            name: p.name,
            type: p.type.getDisplayString(withNullability: true),
            isRequired: p.isRequired,
            isNamed: p.isNamed,
            hasDefault: p.hasDefaultValue,
            defaultValue: p.defaultValueCode,
          );
        }).toList();

        intents.add(_IntentInfo(
          name: method.name,
          returnType: method.returnType.getDisplayString(withNullability: false),
          isAsync: method.returnType.isDartAsyncFuture ||
              method.returnType.isDartAsyncFutureOr,
          params: params,
          debounce: debounceDuration,
          throttle: throttleDuration,
          shouldLog: log,
        ));
      }
    }

    return intents;
  }

  List<_ComputedInfo> _extractComputedProperties(ClassElement element) {
    final computed = <_ComputedInfo>[];

    for (final accessor in element.accessors) {
      if (accessor.isGetter && _computedChecker.hasAnnotationOfExact(accessor)) {
        computed.add(_ComputedInfo(
          name: accessor.name,
          type: accessor.returnType.getDisplayString(withNullability: false),
        ));
      }
    }

    return computed;
  }

  Future<List<_StateVariant>> _findStateVariants(
    BuildStep buildStep,
    String stateType,
  ) async {
    final variants = <_StateVariant>[];

    // Search for the state class
    final glob = Glob('lib/**.dart');

    await for (final assetId in buildStep.findAssets(glob)) {
      try {
        final library = await buildStep.resolver.libraryFor(assetId);

        for (final element in library.topLevelElements) {
          if (element is ClassElement && element.name == stateType) {
            // Found the state class, extract variants from constructors
            for (final constructor in element.constructors) {
              if (constructor.isFactory && constructor.name.isNotEmpty) {
                final variantName = constructor.name;
                final params = constructor.parameters.map((p) {
                  return _ParamInfo(
                    name: p.name,
                    type: p.type.getDisplayString(withNullability: true),
                    isRequired: p.isRequired,
                    isNamed: p.isNamed,
                  );
                }).toList();

                variants.add(_StateVariant(
                  name: variantName,
                  className: '$stateType${_capitalize(variantName)}',
                  params: params,
                ));
              }
            }
            return variants;
          }
        }
      } catch (e) {
        continue;
      }
    }

    return variants;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _generateFeatureCode({
    required String className,
    required String stateType,
    required bool logging,
    required bool injectable,
    required List<_IntentInfo> intents,
    required List<_ComputedInfo> computedProps,
    required List<_StateVariant> stateVariants,
  }) {
    final buffer = StringBuffer();

    // Generate mixin
    _generateMixin(buffer, className, stateType, logging, intents, computedProps, stateVariants);

    buffer.writeln();

    // Generate provider widget
    _generateProviderWidget(buffer, className, stateType);

    buffer.writeln();

    // Generate screen base class
    _generateScreenClass(buffer, className, stateType, stateVariants);

    return buffer.toString();
  }

  void _generateMixin(
    StringBuffer buffer,
    String className,
    String stateType,
    bool logging,
    List<_IntentInfo> intents,
    List<_ComputedInfo> computedProps,
    List<_StateVariant> stateVariants,
  ) {
    buffer.writeln('/// Generated mixin for $className.');
    buffer.writeln('///');
    buffer.writeln('/// Provides helper methods and state handling utilities.');
    buffer.writeln('mixin _\$${className}Mixin on Feature<$stateType> {');

    // Override loggingEnabled
    buffer.writeln('  @override');
    buffer.writeln('  bool get loggingEnabled => $logging;');
    buffer.writeln();

    // Generate when method if we have state variants
    if (stateVariants.isNotEmpty) {
      _generateWhenMethod(buffer, stateType, stateVariants);
      buffer.writeln();
      _generateMaybeWhenMethod(buffer, stateType, stateVariants);
      buffer.writeln();
      _generateMapMethod(buffer, stateType, stateVariants);
    }

    buffer.writeln('}');
  }

  void _generateWhenMethod(
    StringBuffer buffer,
    String stateType,
    List<_StateVariant> variants,
  ) {
    // Generate callback parameters
    final callbackParams = variants.map((v) {
      if (v.params.isEmpty) {
        return 'required T Function() ${v.name}';
      } else {
        final paramTypes = v.params.map((p) => '${p.type} ${p.name}').join(', ');
        return 'required T Function($paramTypes) ${v.name}';
      }
    }).join(',\n    ');

    buffer.writeln('  /// Pattern matches on the current state and returns a value.');
    buffer.writeln('  ///');
    buffer.writeln('  /// All callbacks are required for exhaustive matching.');
    buffer.writeln('  T when<T>({');
    buffer.writeln('    $callbackParams,');
    buffer.writeln('  }) {');
    buffer.writeln('    final s = state;');

    // Generate switch cases
    for (int i = 0; i < variants.length; i++) {
      final variant = variants[i];
      final isFirst = i == 0;
      final prefix = isFirst ? 'if' : '} else if';

      if (variant.params.isEmpty) {
        buffer.writeln('    $prefix (s is ${variant.className}) {');
        buffer.writeln('      return ${variant.name}();');
      } else {
        buffer.writeln('    $prefix (s is ${variant.className}) {');
        final args = variant.params.map((p) => 's.${p.name}').join(', ');
        buffer.writeln('      return ${variant.name}($args);');
      }
    }

    buffer.writeln('    }');
    buffer.writeln("    throw StateError('Unknown state type: \$s');");
    buffer.writeln('  }');
  }

  void _generateMaybeWhenMethod(
    StringBuffer buffer,
    String stateType,
    List<_StateVariant> variants,
  ) {
    // Generate callback parameters
    final callbackParams = variants.map((v) {
      if (v.params.isEmpty) {
        return 'T Function()? ${v.name}';
      } else {
        final paramTypes = v.params.map((p) => '${p.type} ${p.name}').join(', ');
        return 'T Function($paramTypes)? ${v.name}';
      }
    }).join(',\n    ');

    buffer.writeln('  /// Pattern matches on the current state with optional callbacks.');
    buffer.writeln('  ///');
    buffer.writeln('  /// Returns orElse if no callback matches.');
    buffer.writeln('  T maybeWhen<T>({');
    buffer.writeln('    $callbackParams,');
    buffer.writeln('    required T Function() orElse,');
    buffer.writeln('  }) {');
    buffer.writeln('    final s = state;');

    // Generate switch cases
    for (int i = 0; i < variants.length; i++) {
      final variant = variants[i];
      final isFirst = i == 0;
      final prefix = isFirst ? 'if' : '} else if';

      if (variant.params.isEmpty) {
        buffer.writeln('    $prefix (s is ${variant.className} && ${variant.name} != null) {');
        buffer.writeln('      return ${variant.name}();');
      } else {
        buffer.writeln('    $prefix (s is ${variant.className} && ${variant.name} != null) {');
        final args = variant.params.map((p) => 's.${p.name}').join(', ');
        buffer.writeln('      return ${variant.name}($args);');
      }
    }

    buffer.writeln('    }');
    buffer.writeln('    return orElse();');
    buffer.writeln('  }');
  }

  void _generateMapMethod(
    StringBuffer buffer,
    String stateType,
    List<_StateVariant> variants,
  ) {
    // Generate callback parameters
    final callbackParams = variants.map((v) {
      return 'required T Function(${v.className} state) ${v.name}';
    }).join(',\n    ');

    buffer.writeln('  /// Maps the current state to a value using typed callbacks.');
    buffer.writeln('  T map<T>({');
    buffer.writeln('    $callbackParams,');
    buffer.writeln('  }) {');
    buffer.writeln('    final s = state;');

    // Generate switch cases
    for (int i = 0; i < variants.length; i++) {
      final variant = variants[i];
      final isFirst = i == 0;
      final prefix = isFirst ? 'if' : '} else if';

      buffer.writeln('    $prefix (s is ${variant.className}) {');
      buffer.writeln('      return ${variant.name}(s);');
    }

    buffer.writeln('    }');
    buffer.writeln("    throw StateError('Unknown state type: \$s');");
    buffer.writeln('  }');
  }

  void _generateProviderWidget(
    StringBuffer buffer,
    String className,
    String stateType,
  ) {
    buffer.writeln('/// Provider widget that injects [$className] into the widget tree.');
    buffer.writeln('///');
    buffer.writeln('/// Usage:');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// ${className}Provider(');
    buffer.writeln('///   child: const MyWidget(),');
    buffer.writeln('/// )');
    buffer.writeln('/// ```');
    buffer.writeln('class ${className}Provider extends StatelessWidget {');
    buffer.writeln('  const ${className}Provider({');
    buffer.writeln('    super.key,');
    buffer.writeln('    this.create,');
    buffer.writeln('    required this.child,');
    buffer.writeln('  });');
    buffer.writeln();
    buffer.writeln('  /// Optional factory to create the feature.');
    buffer.writeln('  /// If not provided, gets the feature from DI.');
    buffer.writeln('  final $className Function(BuildContext context)? create;');
    buffer.writeln();
    buffer.writeln('  /// The child widget.');
    buffer.writeln('  final Widget child;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return FeatureProvider<$className>(');
    buffer.writeln('      create: create ?? (_) => DragonflyContainer.I.get<$className>(),');
    buffer.writeln('      child: child,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void _generateScreenClass(
    StringBuffer buffer,
    String className,
    String stateType,
    List<_StateVariant> stateVariants,
  ) {
    buffer.writeln('/// Extension methods for using $className in widgets.');
    buffer.writeln('extension ${className}BuildContextExtension on BuildContext {');
    buffer.writeln('  /// Gets the [$className] from the widget tree.');
    buffer.writeln('  $className get ${_uncapitalize(className)} => feature<$className>();');
    buffer.writeln();

    // Generate when builder if we have variants
    if (stateVariants.isNotEmpty) {
      final callbackParams = stateVariants.map((v) {
        if (v.params.isEmpty) {
          return 'required Widget Function() on${_capitalize(v.name)}';
        } else {
          final paramTypes = v.params.map((p) => '${p.type} ${p.name}').join(', ');
          return 'required Widget Function($paramTypes) on${_capitalize(v.name)}';}
      }).join(',\n    ');

      buffer.writeln('  /// Builds a widget based on the current state of [$className].');
      buffer.writeln('  Widget ${_uncapitalize(className)}Builder({');
      buffer.writeln('    $callbackParams,');
      buffer.writeln('  }) {');
      buffer.writeln('    return FeatureBuilder<$className, $stateType>(');
      buffer.writeln('      builder: (context, state) {');
      buffer.writeln('        return state.when(');

      for (final variant in stateVariants) {
        final callbackName = 'on${_capitalize(variant.name)}';
        if (variant.params.isEmpty) {
          buffer.writeln('          ${variant.name}: $callbackName,');
        } else {
          final paramNames = variant.params.map((p) => p.name).join(', ');
          buffer.writeln('          ${variant.name}: ($paramNames) => $callbackName($paramNames),');
        }
      }

      buffer.writeln('        );');
      buffer.writeln('      },');
      buffer.writeln('    );');
      buffer.writeln('  }');
    }

    buffer.writeln('}');
  }

  String _uncapitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toLowerCase() + s.substring(1);
  }
}

class _IntentInfo {
  final String name;
  final String returnType;
  final bool isAsync;
  final List<_ParamInfo> params;
  final Duration? debounce;
  final Duration? throttle;
  final bool shouldLog;

  _IntentInfo({
    required this.name,
    required this.returnType,
    required this.isAsync,
    required this.params,
    this.debounce,
    this.throttle,
    required this.shouldLog,
  });
}

class _ComputedInfo {
  final String name;
  final String type;

  _ComputedInfo({required this.name, required this.type});
}

class _StateVariant {
  final String name;
  final String className;
  final List<_ParamInfo> params;

  _StateVariant({
    required this.name,
    required this.className,
    required this.params,
  });
}

class _ParamInfo {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNamed;
  final bool hasDefault;
  final String? defaultValue;

  _ParamInfo({
    required this.name,
    required this.type,
    this.isRequired = false,
    this.isNamed = false,
    this.hasDefault = false,
    this.defaultValue,
  });
}
