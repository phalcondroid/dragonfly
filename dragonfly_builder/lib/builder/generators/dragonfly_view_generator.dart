import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @DragonflyView annotated classes.
///
/// This generator creates a mixin that provides:
/// - State-aware widget builder method
/// - Event dispatch helpers
/// - BLoC access helpers
///
/// Example input:
/// ```dart
/// @DragonflyView(
///   bloc: UserBloc,
///   event: UserEvent,
///   state: UserState,
/// )
/// class UserView extends StatelessWidget with _$UserViewMixin {
///   const UserView({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return buildStateWidget(
///       context,
///       onInitial: () => WelcomeWidget(),
///       onLoading: () => CircularProgressIndicator(),
///       onLoaded: (user) => UserDetails(user: user),
///       onError: (message) => ErrorText(message),
///     );
///   }
/// }
/// ```
class DragonflyViewGenerator
    extends GeneratorForAnnotation<DragonflyView> {
  final _formatter = DartFormatter();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@DragonflyViewAnnotation can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final blocType = _getTypeName(annotation.read('bloc'));
    final eventType = _getTypeName(annotation.read('event'));
    final stateType = _getTypeName(annotation.read('state'));
    final autoProvide = annotation.read('autoProvide').boolValue;
    final generateListener = annotation.read('generateListener').boolValue;

    // Find state variants by analyzing the state file
    final stateVariants = await _findStateVariants(buildStep, stateType);

    try {
      final code = _generateViewMixin(
        className,
        blocType,
        eventType,
        stateType,
        stateVariants,
        autoProvide,
        generateListener,
      );

      return _formatter.format(code);
    } catch (e, stackTrace) {
      log.severe('DragonflyViewGenerator error: $e\n$stackTrace');
      return '// Error generating view code: $e';
    }
  }

  String _getTypeName(ConstantReader reader) {
    final type = reader.typeValue;
    return type.getDisplayString(withNullability: false);
  }

  /// Finds state variants by scanning the codebase for the state class.
  Future<List<_StateVariant>> _findStateVariants(
    BuildStep buildStep,
    String stateType,
  ) async {
    final variants = <_StateVariant>[];

    // Search for the state class in the lib folder
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
                  return _StateParam(
                    name: p.name,
                    type: p.type.getDisplayString(withNullability: true),
                    isRequired: p.isRequired,
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
        // Ignore files that can't be resolved
        continue;
      }
    }

    return variants;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _generateViewMixin(
    String className,
    String blocType,
    String eventType,
    String stateType,
    List<_StateVariant> stateVariants,
    bool autoProvide,
    bool generateListener,
  ) {
    final buffer = StringBuffer();

    // Generate the mixin
    buffer.writeln('/// Generated mixin for $className.');
    buffer.writeln('///');
    buffer.writeln('/// Provides state-aware widget builders and bloc helpers.');
    buffer.writeln('mixin _\$${className}Mixin on StatelessWidget {');

    // Generate bloc getter
    buffer.writeln('  /// Gets the bloc from the context.');
    buffer.writeln('  $blocType getBloc(BuildContext context) {');
    buffer.writeln('    return DragonflyBlocProvider.of<$blocType>(context);');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate dispatch helper
    buffer.writeln('  /// Dispatches an event to the bloc.');
    buffer.writeln('  void dispatch(BuildContext context, $eventType event) {');
    buffer.writeln('    getBloc(context).add(event);');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate state builder method
    if (stateVariants.isNotEmpty) {
      _generateStateBuilderMethod(buffer, blocType, stateType, stateVariants);
    } else {
      // Fallback generic builder
      _generateGenericStateBuilder(buffer, blocType, stateType);
    }

    // Generate listener wrapper if requested
    if (generateListener) {
      _generateListenerWrapper(buffer, blocType, stateType);
    }

    buffer.writeln('}');

    // Generate provider wrapper widget for auto-injection
    buffer.writeln();
    _generateProviderWrapper(buffer, className, blocType);

    // Generate standalone state builder widget
    if (stateVariants.isNotEmpty) {
      buffer.writeln();
      _generateStateBuilderWidget(buffer, stateType, stateVariants);
    }

    return buffer.toString();
  }

  void _generateProviderWrapper(
    StringBuffer buffer,
    String className,
    String blocType,
  ) {
    buffer.writeln('/// Wrapper widget that provides [$blocType] to [$className].');
    buffer.writeln('///');
    buffer.writeln('/// Use this instead of manually wrapping with DragonflyBlocProvider.');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// // Instead of:');
    buffer.writeln('/// DragonflyBlocProvider<$blocType>(');
    buffer.writeln('///   create: (context) => DragonflyContainer.I.get<$blocType>(),');
    buffer.writeln('///   child: const $className(),');
    buffer.writeln('/// )');
    buffer.writeln('///');
    buffer.writeln('/// // Use:');
    buffer.writeln('/// const ${className}Provider()');
    buffer.writeln('/// ```');
    buffer.writeln('class ${className}Provider extends StatelessWidget {');
    buffer.writeln('  const ${className}Provider({super.key});');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return DragonflyBlocProvider<$blocType>(');
    buffer.writeln('      create: (context) => DragonflyContainer.I.get<$blocType>(),');
    buffer.writeln('      child: const $className(),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void _generateStateBuilderMethod(
    StringBuffer buffer,
    String blocType,
    String stateType,
    List<_StateVariant> variants,
  ) {
    // Generate callback type parameters
    final callbackParams = variants.map((v) {
      if (v.params.isEmpty) {
        return 'required Widget Function() on${_capitalize(v.name)}';
      } else {
        final paramTypes = v.params.map((p) => '${p.type} ${p.name}').join(', ');
        return 'required Widget Function($paramTypes) on${_capitalize(v.name)}';
      }
    }).join(',\n    ');

    buffer.writeln('  /// Builds a widget based on the current state.');
    buffer.writeln('  ///');
    buffer.writeln('  /// Each callback corresponds to a state variant.');
    buffer.writeln('  Widget buildStateWidget(');
    buffer.writeln('    BuildContext context, {');
    buffer.writeln('    $callbackParams,');
    buffer.writeln('  }) {');
    buffer.writeln('    return DragonflyBlocBuilder<$blocType, $stateType>(');
    buffer.writeln('      builder: (context, state) {');
    buffer.writeln('        return state.when(');

    // Generate when cases
    for (final variant in variants) {
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
    buffer.writeln();
  }

  void _generateGenericStateBuilder(
    StringBuffer buffer,
    String blocType,
    String stateType,
  ) {
    buffer.writeln('  /// Builds a widget based on the current state.');
    buffer.writeln('  ///');
    buffer.writeln('  /// Use the state\'s when/map methods to handle different variants.');
    buffer.writeln('  Widget buildStateWidget(');
    buffer.writeln('    BuildContext context,');
    buffer.writeln('    Widget Function($stateType state) builder,');
    buffer.writeln('  ) {');
    buffer.writeln('    return DragonflyBlocBuilder<$blocType, $stateType>(');
    buffer.writeln('      builder: (context, state) => builder(state),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateListenerWrapper(
    StringBuffer buffer,
    String blocType,
    String stateType,
  ) {
    buffer.writeln('  /// Wraps a child widget with a state listener.');
    buffer.writeln('  ///');
    buffer.writeln('  /// The listener is called whenever the state changes.');
    buffer.writeln('  Widget withStateListener(');
    buffer.writeln('    BuildContext context, {');
    buffer.writeln('    required Widget child,');
    buffer.writeln('    required void Function(BuildContext, $stateType) listener,');
    buffer.writeln('    bool Function($stateType, $stateType)? listenWhen,');
    buffer.writeln('  }) {');
    buffer.writeln('    return DragonflyBlocListener<$blocType, $stateType>(');
    buffer.writeln('      listener: listener,');
    buffer.writeln('      listenWhen: listenWhen,');
    buffer.writeln('      child: child,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateStateBuilderWidget(
    StringBuffer buffer,
    String stateType,
    List<_StateVariant> variants,
  ) {
    final widgetName = '${stateType}BuilderWidget';

    // Generate callback parameters
    final fieldDeclarations = variants.map((v) {
      if (v.params.isEmpty) {
        return '  final Widget Function() on${_capitalize(v.name)};';
      } else {
        final paramTypes = v.params.map((p) => '${p.type} ${p.name}').join(', ');
        return '  final Widget Function($paramTypes) on${_capitalize(v.name)};';
      }
    }).join('\n');

    final constructorParams = variants.map((v) {
      return '    required this.on${_capitalize(v.name)},';
    }).join('\n');

    buffer.writeln('/// A standalone widget that builds based on [$stateType] variants.');
    buffer.writeln('class $widgetName extends StatelessWidget {');
    buffer.writeln('  const $widgetName({');
    buffer.writeln('    super.key,');
    buffer.writeln('    required this.state,');
    buffer.writeln(constructorParams);
    buffer.writeln('  });');
    buffer.writeln();
    buffer.writeln('  final $stateType state;');
    buffer.writeln(fieldDeclarations);
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return state.when(');

    for (final variant in variants) {
      final callbackName = 'on${_capitalize(variant.name)}';
      if (variant.params.isEmpty) {
        buffer.writeln('      ${variant.name}: $callbackName,');
      } else {
        final paramNames = variant.params.map((p) => p.name).join(', ');
        buffer.writeln('      ${variant.name}: ($paramNames) => $callbackName($paramNames),');
      }
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}

class _StateVariant {
  final String name;
  final String className;
  final List<_StateParam> params;

  _StateVariant({
    required this.name,
    required this.className,
    required this.params,
  });
}

class _StateParam {
  final String name;
  final String type;
  final bool isRequired;

  _StateParam({
    required this.name,
    required this.type,
    required this.isRequired,
  });
}
