import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/helper/state_manager_descriptor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for `@StateView` annotated widgets.
///
/// Emits a `part` file (`<name>.view.dart`) containing a mixin named after
/// the bound state manager (`$UserStateManager`). The mixin flattens the
/// whole state API onto the widget:
///
/// - one dispatcher method per `@Event` (`initialize(session)`),
/// - one forwarder per plain method (`saveUsers(user)`),
/// - `when(...)` — rebuilds on state change, all callbacks optional plus a
///   required `orElse`,
/// - `build<Event>(...)` — typed builder that builds only for that variant,
/// - `buildFor('event', ...)` — string-keyed escape hatch (payload is
///   `dynamic`).
///
/// The controller is resolved from the DI container, so no provider wrapping
/// is needed anywhere.
///
/// The source file must add `part '<name>.view.dart';` and import Flutter
/// widgets, `package:dragonfly/dragonfly.dart`, the state manager file, and
/// (in StateModel mode) the state model file — generated code uses the source
/// library's imports, like every other Dragonfly generator.
///
/// Several views in one file may bind the same state manager: the mixin is
/// emitted once per unique manager.
class ViewGenerator extends GeneratorForAnnotation<StateView> {
  static final _viewChecker =
      TypeChecker.typeNamed(StateView, inPackage: 'dragonfly_annotations');
  static final _stateManagerChecker =
      TypeChecker.typeNamed(StateManager, inPackage: 'dragonfly_annotations');

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final descriptors = <String, StateManagerDescriptor>{};

    for (final annotated in library.annotatedWith(_viewChecker)) {
      final element = annotated.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@StateView can only be applied to classes.',
          element: element,
        );
      }

      final managerType = annotated.annotation.read('stateManager').typeValue;
      final managerElement = managerType.element;
      if (managerElement is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@StateView stateManager does not resolve to a class.',
          element: element,
        );
      }

      final managerAnnotation =
          _stateManagerChecker.firstAnnotationOfExact(managerElement);
      if (managerAnnotation == null) {
        throw InvalidGenerationSourceError(
          '@StateView can only bind to a @StateManager class. '
          '${managerElement.name} has no @StateManager annotation.',
          element: element,
        );
      }

      final d = await StateManagerDescriber.describe(
        managerElement,
        ConstantReader(managerAnnotation),
        buildStep,
      );
      descriptors.putIfAbsent(d.mixinName, () => d);
    }

    if (descriptors.isEmpty) return '';

    try {
      final buffer = StringBuffer();
      for (final d in descriptors.values) {
        _generateViewMixin(buffer, d);
        buffer.writeln();
      }
      return buffer.toString();
    } catch (e, stackTrace) {
      log.severe('ViewGenerator error: $e\n$stackTrace');
      return '// Error generating view code: $e';
    }
  }

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Not used — [generate] is overridden to dedupe mixins per manager.
    throw UnimplementedError();
  }

  void _generateViewMixin(StringBuffer buffer, StateManagerDescriptor d) {
    final controllerGetter = '_${d.className[0].toLowerCase()}'
        '${d.className.substring(1)}Controller';

    buffer.writeln('/// View mixin for [${d.className}].');
    buffer.writeln('///');
    buffer.writeln('/// Flattens the state API onto the bound widget: dispatch events by');
    buffer.writeln('/// calling them (`initialize(session)`), rebuild from state with');
    buffer.writeln('/// [when], [buildFor] or the typed `build<Event>` builders.');
    buffer.writeln('mixin ${d.mixinName} {');
    buffer.writeln(
        '  ${d.controllerName} get $controllerGetter =>');
    buffer.writeln(
        '      DragonflyContainer.I.get<${d.controllerName}>();');
    buffer.writeln();
    buffer.writeln('  /// The current state of the bound controller.');
    buffer.writeln(
        '  ${d.stateType} get currentState => $controllerGetter.state;');

    // Dispatchers for @Event methods
    for (final event in d.events) {
      buffer.writeln();
      buffer.writeln('  /// Dispatches the `${event.name}` event.');
      buffer.writeln(
          '  Future<void> ${event.name}(${buildParamList(event.params)}) =>');
      buffer.writeln(
          '      $controllerGetter.${event.name}(${buildArgList(event.params)});');
    }

    // Forwarders for plain methods
    for (final method in d.methods) {
      buffer.writeln();
      buffer.writeln(
          '  ${method.returnType} ${method.name}(${buildParamList(method.params)}) =>');
      buffer.writeln(
          '      $controllerGetter.${method.name}(${buildArgList(method.params)});');
    }

    buffer.writeln();
    _generateWhen(buffer, d, controllerGetter);

    for (final v in d.variants) {
      buffer.writeln();
      _generateTypedBuilder(buffer, d, v, controllerGetter);
    }

    buffer.writeln();
    _generateBuildFor(buffer, d, controllerGetter);

    buffer.writeln('}');
  }

  // ── when ─────────────────────────────────────────────────────────────────

  void _generateWhen(
    StringBuffer buffer,
    StateManagerDescriptor d,
    String controllerGetter,
  ) {
    buffer.writeln('  /// Rebuilds on every state change. All variant callbacks are');
    buffer.writeln('  /// optional; [orElse] covers the unmatched ones.');
    buffer.writeln('  Widget when({');
    for (final v in d.variants) {
      buffer.writeln('    ${_widgetCallbackType(v)}? ${v.name},');
    }
    buffer.writeln('    required Widget Function() orElse,');
    buffer.writeln('  }) {');
    buffer.writeln(
        '    return DragonflyStateBuilder<${d.stateType}>(');
    buffer.writeln('      controller: $controllerGetter,');
    buffer.writeln('      builder: (context, state) => state.maybeWhen(');
    for (final v in d.variants) {
      buffer.writeln('        ${v.name}: ${v.name},');
    }
    buffer.writeln('        orElse: orElse,');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  String _widgetCallbackType(StateVariantDescriptor v) {
    if (!v.hasPayload) return 'Widget Function()';
    final args = v.fields.map((f) => '${f.type} ${f.name}').join(', ');
    return 'Widget Function($args)';
  }

  // ── build<Event> ─────────────────────────────────────────────────────────

  void _generateTypedBuilder(
    StringBuffer buffer,
    StateManagerDescriptor d,
    StateVariantDescriptor v,
    String controllerGetter,
  ) {
    final capitalized = v.name[0].toUpperCase() + v.name.substring(1);
    final builderType = _widgetCallbackType(v);
    final args = v.fields.map((f) => 'state.${f.name}').join(', ');

    buffer.writeln(
        '  /// Builds only while the state is `${d.stateType}.${v.name}`.');
    buffer.writeln(
        '  Widget build$capitalized($builderType builder, {Widget Function()? orElse}) {');
    buffer.writeln(
        '    return DragonflyStateBuilder<${d.stateType}>(');
    buffer.writeln('      controller: $controllerGetter,');
    buffer.writeln('      builder: (context, state) => state is ${v.className}');
    buffer.writeln('          ? builder($args)');
    buffer.writeln("          : orElse?.call() ?? const SizedBox.shrink(),");
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  // ── buildFor ─────────────────────────────────────────────────────────────

  void _generateBuildFor(
    StringBuffer buffer,
    StateManagerDescriptor d,
    String controllerGetter,
  ) {
    buffer.writeln('  /// String-keyed builder. The payload is `dynamic` — prefer the');
    buffer.writeln('  /// typed `build<Event>` builders where possible.');
    buffer.writeln('  ///');
    buffer.writeln(
        '  /// Payload rules: zero-field variants pass `null`, single-field variants');
    buffer.writeln(
        '  /// pass the field value, multi-field variants pass the state object.');
    buffer.writeln('  Widget buildFor(');
    buffer.writeln('    String event,');
    buffer.writeln('    Widget Function(dynamic value) builder, {');
    buffer.writeln('    Widget Function()? orElse,');
    buffer.writeln('  }) {');
    buffer.writeln(
        '    return DragonflyStateBuilder<${d.stateType}>(');
    buffer.writeln('      controller: $controllerGetter,');
    buffer.writeln('      builder: (context, state) {');
    buffer.writeln('        final matched = switch (state) {');
    for (final v in d.variants) {
      buffer.writeln(
          "          ${v.className}() => event == '${v.name}',");
    }
    buffer.writeln('        };');
    buffer.writeln('        if (!matched) {');
    buffer.writeln("          return orElse?.call() ?? const SizedBox.shrink();");
    buffer.writeln('        }');
    buffer.writeln('        final value = switch (state) {');
    for (final v in d.variants) {
      if (v.fields.isEmpty) {
        buffer.writeln('          ${v.className}() => null,');
      } else if (v.fields.length == 1) {
        buffer.writeln(
            '          ${v.className}(:final ${v.fields.first.name}) => ${v.fields.first.name},');
      } else {
        buffer.writeln('          ${v.className}() => state,');
      }
    }
    buffer.writeln('        };');
    buffer.writeln('        return builder(value);');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }
}
