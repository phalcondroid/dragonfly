import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @DragonflyStateManager annotated classes.
///
/// This generator creates:
/// - A mixin with helper methods for the state manager
/// - A provider widget for easy injection
/// - Individual state builder widgets for each state variant
/// - Extension methods for using the state manager in widgets
///
/// Example input:
/// ```dart
/// @DragonflyStateManager()
/// class CharacterStateManager extends StateManager<CharacterState> {
///   @StateAction()
///   Future<void> fetchCharacter(int id) async { ... }
/// }
/// ```
///
/// Generated output includes widgets like:
/// ```dart
/// CharacterLoaded(
///   builder: (Character character) => Widget,
///   buildWhen: (oldState, newState) => bool,
/// )
/// ```
class DragonflyStateManagerGenerator
    extends GeneratorForAnnotation<DragonflyStateManager> {
  final _formatter = DartFormatter();

  static final _actionChecker = TypeChecker.fromRuntime(StateAction);
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
        '@DragonflyStateManager can only be applied to classes.',
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
      final code = _generateStateManagerCode(
        className: className,
        stateType: stateType,
        logging: logging,
        injectable: injectable,
        actions: intents,
        computedProps: computedProps,
        stateVariants: stateVariants,
      );

      return _formatter.format(code);
    } catch (e, stackTrace) {
      log.severe('DragonflyStateManagerGenerator error: $e\n$stackTrace');
      return '// Error generating state manager code: $e';
    }
  }

  String _extractStateType(ClassElement element) {
    // Look for StateManager<S> or Feature<S> in supertype
    for (final supertype in element.allSupertypes) {
      if (supertype.element.name == 'StateManager' ||
          supertype.element.name == 'Feature') {
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

  String _uncapitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toLowerCase() + s.substring(1);
  }

  /// Gets the base name without "StateManager" or "Feature" suffix
  String _getBaseName(String className) {
    if (className.endsWith('StateManager')) {
      return className.substring(0, className.length - 12);
    }
    if (className.endsWith('Feature')) {
      return className.substring(0, className.length - 7);
    }
    return className;
  }

  String _generateStateManagerCode({
    required String className,
    required String stateType,
    required bool logging,
    required bool injectable,
    required List<_IntentInfo> actions,
    required List<_ComputedInfo> computedProps,
    required List<_StateVariant> stateVariants,
  }) {
    final buffer = StringBuffer();
    final baseName = _getBaseName(className);

    // Generate mixin
    _generateMixin(buffer, className, stateType, logging, actions, computedProps, stateVariants);

    buffer.writeln();

    // Generate provider widget
    _generateProviderWidget(buffer, className, stateType);

    buffer.writeln();

    // Generate individual state builder widgets for each variant
    if (stateVariants.isNotEmpty) {
      _generateStateBuilderWidgets(buffer, className, stateType, baseName, stateVariants);
      buffer.writeln();
    }

    // Generate extension methods
    _generateExtensionMethods(buffer, className, stateType, baseName, stateVariants);

    return buffer.toString();
  }

  void _generateMixin(
    StringBuffer buffer,
    String className,
    String stateType,
    bool logging,
    List<_IntentInfo> actions,
    List<_ComputedInfo> computedProps,
    List<_StateVariant> stateVariants,
  ) {
    buffer.writeln('/// Generated mixin for $className.');
    buffer.writeln('///');
    buffer.writeln('/// Provides logging configuration.');
    buffer.writeln('/// State pattern matching (when, maybeWhen, map) is available directly on the state.');
    buffer.writeln('mixin _\$${className}Mixin on StateManager<$stateType> {');

    // Override loggingEnabled
    buffer.writeln('  @override');
    buffer.writeln('  bool get loggingEnabled => $logging;');

    buffer.writeln('}');
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
    buffer.writeln('  /// Optional factory to create the state manager.');
    buffer.writeln('  /// If not provided, gets the state manager from DI.');
    buffer.writeln('  final $className Function(BuildContext context)? create;');
    buffer.writeln();
    buffer.writeln('  /// The child widget.');
    buffer.writeln('  final Widget child;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return StateManagerProvider<$className>(');
    buffer.writeln('      create: create ?? (_) => DragonflyContainer.I.get<$className>(),');
    buffer.writeln('      child: child,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void _generateStateBuilderWidgets(
    StringBuffer buffer,
    String className,
    String stateType,
    String baseName,
    List<_StateVariant> stateVariants,
  ) {
    for (final variant in stateVariants) {
      _generateSingleStateBuilder(buffer, className, stateType, baseName, variant);
      buffer.writeln();
    }
  }

  void _generateSingleStateBuilder(
    StringBuffer buffer,
    String className,
    String stateType,
    String baseName,
    _StateVariant variant,
  ) {
    final widgetName = '$baseName${_capitalize(variant.name)}';
    final hasParams = variant.params.isNotEmpty;

    // Generate builder function type
    String builderType;
    if (hasParams) {
      final paramTypes = variant.params.map((p) => '${p.type} ${p.name}').join(', ');
      builderType = 'Widget Function($paramTypes)';
    } else {
      builderType = 'Widget Function()';
    }

    buffer.writeln('/// Builder widget that only builds when state is [${variant.className}].');
    buffer.writeln('///');
    buffer.writeln('/// Usage:');
    buffer.writeln('/// ```dart');
    if (hasParams) {
      final exampleParams = variant.params.map((p) => p.name).join(', ');
      buffer.writeln('/// $widgetName(');
      buffer.writeln('///   builder: ($exampleParams) => MyWidget($exampleParams),');
      buffer.writeln('/// )');
    } else {
      buffer.writeln('/// $widgetName(');
      buffer.writeln('///   builder: () => const MyWidget(),');
      buffer.writeln('/// )');
    }
    buffer.writeln('/// ```');
    buffer.writeln('class $widgetName extends StatelessWidget {');
    buffer.writeln('  const $widgetName({');
    buffer.writeln('    super.key,');
    buffer.writeln('    required this.builder,');
    buffer.writeln('    this.buildWhen,');
    buffer.writeln('    this.orElse,');
    if (hasParams) {
      for (final param in variant.params) {
        final nullableType = param.type.endsWith('?') ? param.type : '${param.type}?';
        buffer.writeln('    this.initial${_capitalize(param.name)},');
      }
    }
    buffer.writeln('  });');
    buffer.writeln();
    buffer.writeln('  /// Builder function called with state parameters when state is [${variant.className}].');
    buffer.writeln('  final $builderType builder;');
    buffer.writeln();
    buffer.writeln('  /// Optional function to determine if the builder should be called.');
    buffer.writeln('  /// Receives the previous and current state.');
    buffer.writeln('  final bool Function($stateType previous, $stateType current)? buildWhen;');
    buffer.writeln();
    buffer.writeln('  /// Optional widget to show when state is not [${variant.className}].');
    buffer.writeln('  /// Defaults to an empty SizedBox.');
    buffer.writeln('  final Widget Function()? orElse;');

    // Add initial data parameters if the state has parameters
    if (hasParams) {
      buffer.writeln();
      for (final param in variant.params) {
        final nullableType = param.type.endsWith('?') ? param.type : '${param.type}?';
        buffer.writeln('  /// Initial value for ${param.name} before state loads.');
        buffer.writeln('  final $nullableType initial${_capitalize(param.name)};');
      }
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return StateManagerBuilder<$className, $stateType>(');
    buffer.writeln('      buildWhen: buildWhen,');
    buffer.writeln('      builder: (context, state) {');
    buffer.writeln('        if (state is ${variant.className}) {');
    if (hasParams) {
      final paramNames = variant.params.map((p) => 'state.${p.name}').join(', ');
      buffer.writeln('          return builder($paramNames);');
    } else {
      buffer.writeln('          return builder();');
    }
    buffer.writeln('        }');

    // Handle initial data if provided
    if (hasParams) {
      buffer.writeln('        // Check if initial data is provided');
      final hasInitialCheck = variant.params.map((p) => 'initial${_capitalize(p.name)} != null').join(' && ');
      buffer.writeln('        if ($hasInitialCheck) {');
      final initialParams = variant.params.map((p) => 'initial${_capitalize(p.name)}!').join(', ');
      buffer.writeln('          return builder($initialParams);');
      buffer.writeln('        }');
    }

    buffer.writeln('        return orElse?.call() ?? const SizedBox.shrink();');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void _generateExtensionMethods(
    StringBuffer buffer,
    String className,
    String stateType,
    String baseName,
    List<_StateVariant> stateVariants,
  ) {
    buffer.writeln('/// Extension methods for using $className in widgets.');
    buffer.writeln('extension ${className}BuildContextExtension on BuildContext {');
    buffer.writeln('  /// Gets the [$className] from the widget tree.');
    buffer.writeln('  $className get ${_uncapitalize(className)} => stateManager<$className>();');
    buffer.writeln();

    // Generate convenience getter for backward compatibility
    final baseLower = _uncapitalize(baseName);
    if (_uncapitalize(className) != '${baseLower}Feature') {
      buffer.writeln('  /// Alias for backward compatibility.');
      buffer.writeln('  @Deprecated(\'Use ${_uncapitalize(className)} instead\')');
      buffer.writeln('  $className get ${baseLower}Feature => stateManager<$className>();');
      buffer.writeln();
    }

    // Generate when builder if we have variants (keeping for backward compatibility)
    if (stateVariants.isNotEmpty) {
      final callbackParams = stateVariants.map((v) {
        if (v.params.isEmpty) {
          return 'required Widget Function() on${_capitalize(v.name)}';
        } else {
          final paramTypes = v.params.map((p) => '${p.type} ${p.name}').join(', ');
          return 'required Widget Function($paramTypes) on${_capitalize(v.name)}';
        }
      }).join(',\n    ');

      buffer.writeln('  /// Builds a widget based on the current state of [$className].');
      buffer.writeln('  /// Consider using individual state builders like [${baseName}Loaded] instead.');
      buffer.writeln('  Widget ${_uncapitalize(className)}Builder({');
      buffer.writeln('    $callbackParams,');
      buffer.writeln('  }) {');
      buffer.writeln('    return StateManagerBuilder<$className, $stateType>(');
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
