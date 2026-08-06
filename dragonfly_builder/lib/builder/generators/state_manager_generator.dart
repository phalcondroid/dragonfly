import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/helper/state_manager_descriptor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for `@StateManager` annotated classes.
///
/// Emits a `part` file (`<name>.state_manager.dart`) containing:
///
/// - **easy mode**: the sealed state class (`XState`) with the built-in
///   `initial` / `loading` / `error` variants plus one variant per `@Event`
///   method, with `when` / `maybeWhen` pattern matching.
/// - the controller (`$XController extends DragonflyController<XState>`) that
///   wraps the annotated class: every `@Event` method becomes a dispatcher
///   that emits `loading`, invokes the delegate, and emits the result variant
///   (or `error`); plain public methods are forwarded untouched.
///
/// The source file must add `part '<name>.state_manager.dart';` and import
/// `package:dragonfly/dragonfly.dart` (plus, in StateModel mode, the state
/// model file) — generated code uses the source library's imports, like every
/// other Dragonfly generator.
class StateManagerGenerator extends GeneratorForAnnotation<StateManager> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@StateManager can only be applied to classes.',
        element: element,
      );
    }

    try {
      final d = await StateManagerDescriber.describe(element, annotation, buildStep);

      final buffer = StringBuffer();
      if (d.easyMode) {
        _generateStateClass(buffer, d);
        buffer.writeln();
      }
      _generateController(buffer, d);

      return buffer.toString();
    } catch (e, stackTrace) {
      log.severe('StateManagerGenerator error: $e\n$stackTrace');
      return '// Error generating state manager code: $e';
    }
  }

  // ── Easy mode: sealed state class ────────────────────────────────────────

  void _generateStateClass(StringBuffer buffer, StateManagerDescriptor d) {
    final s = d.stateType;

    buffer.writeln('/// State for [${d.className}], generated from its `@Event` methods.');
    buffer.writeln('///');
    buffer.writeln('/// Built-in variants: `initial` (starting state), `loading`');
    buffer.writeln('/// (emitted before every event body runs) and `error`');
    buffer.writeln('/// (emitted when an event throws).');
    buffer.writeln('sealed class $s {');
    buffer.writeln('  const $s._();');
    buffer.writeln();

    // Factory constructors
    for (final v in d.variants) {
      final params = buildParamList(v.fields);
      buffer.writeln(
          '  const factory $s.${v.name}($params) = ${v.className};');
    }
    buffer.writeln();

    // when — all callbacks required
    buffer.writeln('  /// Pattern match over all variants. Every callback is required.');
    buffer.writeln('  T when<T>({');
    for (final v in d.variants) {
      buffer.writeln('    required ${_callbackType(v)} ${v.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final self = this;');
    buffer.writeln('    return switch (self) {');
    for (final v in d.variants) {
      buffer.writeln(
          '      ${v.className}() => ${v.name}(${_fieldArgs(v)}),');
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();

    // maybeWhen — all callbacks optional, orElse required
    buffer.writeln('  /// Pattern match over variants, falling back to [orElse].');
    buffer.writeln('  T maybeWhen<T>({');
    for (final v in d.variants) {
      buffer.writeln('    ${_callbackType(v)}? ${v.name},');
    }
    buffer.writeln('    required T Function() orElse,');
    buffer.writeln('  }) {');
    buffer.writeln('    final self = this;');
    buffer.writeln('    return switch (self) {');
    for (final v in d.variants) {
      buffer.writeln(
          '      ${v.className}() => ${v.name}?.call(${_fieldArgs(v)}) ?? orElse(),');
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    // Variant classes
    for (final v in d.variants) {
      _generateVariantClass(buffer, d, v);
      buffer.writeln();
    }
  }

  String _callbackType(StateVariantDescriptor v) {
    if (!v.hasPayload) return 'T Function()';
    final args = v.fields.map((f) => '${f.type} ${f.name}').join(', ');
    return 'T Function($args)';
  }

  String _fieldArgs(StateVariantDescriptor v) =>
      v.fields.map((f) => 'self.${f.name}').join(', ');

  void _generateVariantClass(
    StringBuffer buffer,
    StateManagerDescriptor d,
    StateVariantDescriptor v,
  ) {
    buffer.writeln('/// `${d.stateType}.${v.name}` variant.');
    buffer.writeln('class ${v.className} extends ${d.stateType} {');
    final ctorParams = v.fields.map((f) {
      final prefix = f.isRequired ? 'required ' : '';
      final suffix = f.hasDefault ? ' = ${f.defaultValue}' : '';
      return '${prefix}this.${f.name}$suffix';
    }).join(', ');
    final params = v.fields.any((f) => f.isNamed)
        ? '{$ctorParams}'
        : ctorParams;
    buffer.writeln('  const ${v.className}($params) : super._();');
    buffer.writeln();
    for (final f in v.fields) {
      buffer.writeln('  final ${f.type} ${f.name};');
    }
    if (v.fields.isNotEmpty) buffer.writeln();

    // toString
    final fieldsStr =
        v.fields.map((f) => '${f.name}: \$${f.name}').join(', ');
    buffer.writeln('  @override');
    buffer.writeln(
        "  String toString() => '${d.stateType}.${v.name}($fieldsStr)';");

    // equality
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  bool operator ==(Object other) =>');
    buffer.writeln('      identical(this, other) ||');
    buffer.write(
        '      other is ${v.className} && runtimeType == other.runtimeType');
    for (final f in v.fields) {
      buffer.write(' && ${f.name} == other.${f.name}');
    }
    buffer.writeln(';');
    buffer.writeln();
    buffer.writeln('  @override');
    if (v.fields.isEmpty) {
      buffer.writeln('  int get hashCode => runtimeType.hashCode;');
    } else if (v.fields.length == 1) {
      buffer.writeln('  int get hashCode => ${v.fields.first.name}.hashCode;');
    } else {
      buffer.writeln(
          '  int get hashCode => Object.hash(${v.fields.map((f) => f.name).join(', ')});');
    }
    buffer.writeln('}');
  }

  // ── Controller ───────────────────────────────────────────────────────────

  void _generateController(StringBuffer buffer, StateManagerDescriptor d) {
    buffer.writeln('/// Controller for [${d.className}].');
    buffer.writeln('///');
    buffer.writeln('/// Owns the state and wraps the delegate: `@Event` methods emit');
    if (d.autoLoading && d.autoError) {
      buffer.writeln(
          '/// `loading` before the body runs and `error` if it throws.');
    } else if (d.autoLoading) {
      buffer.writeln('/// `loading` before the body runs.');
    }
    buffer.writeln('/// Registered in DI as a lazy singleton by the generated');
    buffer.writeln('/// `configureDependencies`.');
    buffer.writeln(
        'class ${d.controllerName} extends DragonflyController<${d.stateType}> {');
    if (d.initialFromDelegate) {
      // The initial variant takes parameters, so the delegate provides it.
      buffer.writeln('  ${d.controllerName}(${d.className} delegate)');
      buffer.writeln('      : _delegate = delegate,');
      buffer.writeln('        super(delegate.initialState);');
    } else {
      buffer.writeln(
          '  ${d.controllerName}(this._delegate) : super(const ${d.stateType}.${d.initialVariant}());');
    }
    buffer.writeln();
    buffer.writeln('  final ${d.className} _delegate;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  bool get loggingEnabled => ${d.logging};');

    for (final event in d.events) {
      buffer.writeln();
      _generateDispatcher(buffer, d, event);
    }

    for (final method in d.methods) {
      buffer.writeln();
      buffer.writeln(
          '  ${method.returnType} ${method.name}(${buildParamList(method.params)}) =>');
      buffer.writeln('      _delegate.${method.name}(${buildArgList(method.params)});');
    }

    buffer.writeln('}');
  }

  void _generateDispatcher(
    StringBuffer buffer,
    StateManagerDescriptor d,
    EventDescriptor event,
  ) {
    final signature = buildParamList(event.params);
    final args = buildArgList(event.params);
    final policy = <String>[
      if (event.debounce != null)
        'debounce: const Duration(microseconds: ${event.debounce!.inMicroseconds})',
      if (event.throttle != null)
        'throttle: const Duration(microseconds: ${event.throttle!.inMicroseconds})',
    ].join(', ');

    if (policy.isNotEmpty) {
      buffer.writeln(
          '  Future<void> ${event.name}($signature) async =>');
      buffer.writeln(
          "      schedule('${event.name}', () => _${event.name}($args), $policy);");
      buffer.writeln();
      buffer.writeln('  Future<void> _${event.name}($signature) async {');
    } else {
      buffer.writeln('  Future<void> ${event.name}($signature) async {');
    }

    if (d.autoLoading) {
      buffer.writeln(
          '    emit(const ${d.stateType}.loading());');
    }
    buffer.writeln('    try {');

    final awaitKw = event.isAsync ? 'await ' : '';

    if (d.easyMode) {
      if (event.isEither) {
        buffer.writeln(
            '      final result = $awaitKw _delegate.${event.name}($args);');
        buffer.writeln('      result.fold(');
        buffer.writeln(
            '        (failure) => emit(${d.stateType}.error(message: failure.toString())),');
        buffer.writeln(
            '        (value) => emit(${d.stateType}.${event.variantName}(value: value)),');
        buffer.writeln('      );');
      } else if (event.hasPayload) {
        buffer.writeln(
            '      final value = $awaitKw _delegate.${event.name}($args);');
        buffer.writeln(
            '      emit(${d.stateType}.${event.variantName}(value: value));');
      } else {
        buffer.writeln('      $awaitKw _delegate.${event.name}($args);');
        buffer.writeln(
            '      emit(const ${d.stateType}.${event.variantName}());');
      }
    } else {
      // StateModel mode: the method returns the state to emit.
      buffer.writeln(
          '      emit($awaitKw _delegate.${event.name}($args));');
    }

    buffer.writeln('    } catch (e) {');
    if (d.autoError) {
      buffer.writeln(
          '      emit(${d.stateType}.error(message: e.toString()));');
    } else {
      buffer.writeln('      rethrow;');
    }
    buffer.writeln('    }');
    buffer.writeln('  }');
  }
}
