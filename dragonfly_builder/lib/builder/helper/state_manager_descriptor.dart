import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/helper/syntactic_param_reader.dart';
import 'package:source_gen/source_gen.dart';

/// A method/constructor parameter, captured for re-declaration in generated
/// signatures and for argument forwarding.
class ParamDescriptor {
  final String name;
  final String type;
  final bool isNamed;
  final bool isRequired;
  final bool hasDefault;
  final String? defaultValue;

  const ParamDescriptor({
    required this.name,
    required this.type,
    this.isNamed = false,
    this.isRequired = false,
    this.hasDefault = false,
    this.defaultValue,
  });

  factory ParamDescriptor.fromElement(FormalParameterElement p) {
    return ParamDescriptor(
      name: p.name ?? '',
      type: p.type.getDisplayString(),
      isNamed: p.isNamed,
      isRequired: p.isRequired,
      hasDefault: p.hasDefaultValue,
      defaultValue: p.defaultValueCode,
    );
  }

  /// Re-declares the parameter inside a generated parameter list.
  String get declaration {
    if (isNamed) {
      final prefix = isRequired ? 'required ' : '';
      final suffix = hasDefault ? ' = $defaultValue' : '';
      return '$prefix$type $name$suffix';
    }
    return '$type $name';
  }

  /// Forwards the parameter as an argument in a generated call.
  String get forward => isNamed ? '$name: $name' : name;
}

/// Builds the parameter list of a generated method from [params].
String buildParamList(List<ParamDescriptor> params) {
  final positional = <String>[];
  final named = <String>[];
  for (final p in params) {
    (p.isNamed ? named : positional).add(p.declaration);
  }
  return [
    ...positional,
    if (named.isNotEmpty) '{${named.join(', ')}}',
  ].join(', ');
}

/// Builds the argument list forwarding [params] into a call.
String buildArgList(List<ParamDescriptor> params) =>
    params.map((p) => p.forward).join(', ');

/// An `@Event` method of a state manager.
class EventDescriptor {
  final String name;
  final List<ParamDescriptor> params;

  /// Payload type of the matching state variant (easy mode). `null` when the
  /// event has no payload (`void` / `Future<void>`), and in StateModel mode,
  /// where the method returns the state itself.
  final String? payloadType;

  /// Whether the raw return type is `Either<L, R>` (easy mode). The generated
  /// dispatcher folds it: left becomes `error`, right becomes the payload.
  final bool isEither;

  /// The left type when [isEither] is true.
  final String? eitherLeftType;

  /// Whether the method returns the state type directly (StateModel mode).
  final bool returnsState;

  final bool isAsync;
  final Duration? debounce;
  final Duration? throttle;

  const EventDescriptor({
    required this.name,
    required this.params,
    required this.payloadType,
    required this.isEither,
    required this.eitherLeftType,
    required this.returnsState,
    required this.isAsync,
    required this.debounce,
    required this.throttle,
  });

  bool get hasPayload => payloadType != null;

  /// The state variant this event maps to in easy mode.
  String get variantName => name;
}

/// A plain (non-`@Event`) public method, forwarded untouched by the controller.
class PlainMethodDescriptor {
  final String name;
  final String returnType;
  final List<ParamDescriptor> params;

  const PlainMethodDescriptor({
    required this.name,
    required this.returnType,
    required this.params,
  });
}

/// One variant of the state sealed class.
class StateVariantDescriptor {
  /// Variant name as used by `when`/`maybeWhen` (`initial`, `loading`, …).
  final String name;

  /// Concrete class name (`UserStateManagerStateInitial`, `CharacterStateLoaded`).
  final String className;

  /// Payload fields of the variant.
  final List<ParamDescriptor> fields;

  const StateVariantDescriptor({
    required this.name,
    required this.className,
    required this.fields,
  });

  bool get hasPayload => fields.isNotEmpty;
}

/// Everything the state manager and view generators need to know about a
/// `@StateManager` class.
class StateManagerDescriptor {
  /// The annotated class name (`UserStateManager`).
  final String className;

  /// The state type (`UserStateManagerState` in easy mode, the `@StateModel`
  /// type otherwise).
  final String stateType;

  /// Whether the state class is generated from the `@Event` methods (no
  /// `state` argument on the annotation).
  final bool easyMode;

  final bool logging;

  /// Whether dispatchers emit a `loading` state before the event body runs.
  /// Always true in easy mode; in StateModel mode, true when the model
  /// declares a zero-arg `loading` factory.
  final bool autoLoading;

  /// Whether dispatchers catch exceptions into an `error` state. Always true
  /// in easy mode; in StateModel mode, true when the model declares an
  /// `error({required String message})` factory.
  final bool autoError;

  /// Name of the variant used as the controller's starting state.
  final String initialVariant;

  /// When true, the starting state is read from the delegate's `initialState`
  /// getter instead of a const zero-arg `initial` factory. Required in
  /// StateModel mode when `initial` has parameters.
  final bool initialFromDelegate;

  final List<EventDescriptor> events;
  final List<PlainMethodDescriptor> methods;
  final List<StateVariantDescriptor> variants;

  /// Package/relative URI of the library declaring the state manager.
  final String sourceUri;

  /// Package/relative URI of the library declaring the `@StateModel` type
  /// (StateModel mode only).
  final String? stateSourceUri;

  const StateManagerDescriptor({
    required this.className,
    required this.stateType,
    required this.easyMode,
    required this.logging,
    required this.autoLoading,
    required this.autoError,
    required this.initialVariant,
    required this.initialFromDelegate,
    required this.events,
    required this.methods,
    required this.variants,
    required this.sourceUri,
    required this.stateSourceUri,
  });

  /// The generated controller class name (`$UserStateManagerController`).
  String get controllerName => '\$${className}Controller';

  /// The generated view mixin name (`$UserStateManager`).
  String get mixinName => '\$$className';

  /// The URI of the generated state manager file, derived from [sourceUri].
  String get generatedUri => sourceUri.replaceFirst(
        '.dart',
        '.state_manager.dart',
        sourceUri.length - '.dart'.length,
      );

  StateVariantDescriptor variantNamed(String name) =>
      variants.firstWhere((v) => v.name == name);
}

/// Analyzes a `@StateManager` annotated class into a [StateManagerDescriptor].
///
/// Shared by the state manager generator (which emits the controller and, in
/// easy mode, the state class) and the view generator (which emits the view
/// mixin) so both always agree on names, variants and dispatch semantics.
class StateManagerDescriber {
  static final _eventChecker =
      TypeChecker.typeNamed(Event, inPackage: 'dragonfly_annotations');

  static Future<StateManagerDescriptor> describe(
    ClassElement element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final className = element.name ?? '';
    final logging = annotation.peek('logging')?.boolValue ?? false;
    final stateTypeValue = annotation.peek('state')?.typeValue;
    final easyMode = stateTypeValue == null;
    final sourceUri = element.library.uri.toString();

    final events = <EventDescriptor>[];
    final methods = <PlainMethodDescriptor>[];

    for (final method in element.methods) {
      if (method.isStatic || method.isPrivate || method.isSynthetic) continue;
      final name = method.name ?? '';
      if (name == 'toString' || name == 'noSuchMethod' || name == 'hashCode') {
        continue;
      }

      final params =
          method.formalParameters.map(ParamDescriptor.fromElement).toList();

      if (_eventChecker.hasAnnotationOfExact(method)) {
        events.add(_describeEvent(
          method,
          params,
          easyMode: easyMode,
          stateType: easyMode ? null : stateTypeValue.getDisplayString(),
        ));
      } else {
        methods.add(PlainMethodDescriptor(
          name: name,
          returnType: method.returnType.getDisplayString(),
          params: params,
        ));
      }
    }

    if (easyMode) {
      return _describeEasyMode(
        className: className,
        logging: logging,
        events: events,
        methods: methods,
        sourceUri: sourceUri,
      );
    }

    return _describeStateModelMode(
      element: element,
      className: className,
      logging: logging,
      events: events,
      methods: methods,
      sourceUri: sourceUri,
      stateTypeValue: stateTypeValue,
      buildStep: buildStep,
    );
  }

  // ── Easy mode ────────────────────────────────────────────────────────────

  static StateManagerDescriptor _describeEasyMode({
    required String className,
    required bool logging,
    required List<EventDescriptor> events,
    required List<PlainMethodDescriptor> methods,
    required String sourceUri,
  }) {
    final stateType = '${className}State';
    final variants = <StateVariantDescriptor>[
      StateVariantDescriptor(
        name: 'initial',
        className: '${stateType}Initial',
        fields: const [],
      ),
      StateVariantDescriptor(
        name: 'loading',
        className: '${stateType}Loading',
        fields: const [],
      ),
      StateVariantDescriptor(
        name: 'error',
        className: '${stateType}Error',
        fields: const [
          ParamDescriptor(name: 'message', type: 'String', isNamed: true, isRequired: true),
        ],
      ),
      for (final event in events)
        StateVariantDescriptor(
          name: event.variantName,
          className: '$stateType${_capitalize(event.variantName)}',
          fields: [
            if (event.hasPayload)
              ParamDescriptor(
                name: 'value',
                type: event.payloadType!,
                isNamed: true,
                isRequired: true,
              ),
          ],
        ),
    ];

    return StateManagerDescriptor(
      className: className,
      stateType: stateType,
      easyMode: true,
      logging: logging,
      autoLoading: true,
      autoError: true,
      initialVariant: 'initial',
      initialFromDelegate: false,
      events: events,
      methods: methods,
      variants: variants,
      sourceUri: sourceUri,
      stateSourceUri: null,
    );
  }

  // ── StateModel mode ──────────────────────────────────────────────────────

  static Future<StateManagerDescriptor> _describeStateModelMode({
    required ClassElement element,
    required String className,
    required bool logging,
    required List<EventDescriptor> events,
    required List<PlainMethodDescriptor> methods,
    required String sourceUri,
    required DartType stateTypeValue,
    required BuildStep buildStep,
  }) async {
    final stateType = stateTypeValue.getDisplayString();
    final stateElement = stateTypeValue.element;
    if (stateElement is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@StateManager state: $stateType does not resolve to a class.',
        element: element,
      );
    }

    // Variant field types come from the source text: types declared in other
    // generated files resolve to InvalidType at build time, but the source
    // always has the real names.
    final syntactic = await SyntacticParamReader.readFactoryParams(
      buildStep,
      stateElement.library.uri,
      stateType,
    );

    final variants = <StateVariantDescriptor>[];
    for (final constructor in stateElement.constructors) {
      if (!constructor.isFactory) continue;
      final name = constructor.name ?? '';
      if (name.isEmpty) continue;

      final syntacticParams = syntactic[name];
      final fields = syntacticParams != null
          ? syntacticParams
              .map((p) => ParamDescriptor(
                    name: p.name,
                    type: p.type,
                    isNamed: p.isNamed,
                    isRequired: p.isRequired,
                    hasDefault: p.defaultValue != null,
                    defaultValue: p.defaultValue,
                  ))
              .toList()
          : constructor.formalParameters
              .map(ParamDescriptor.fromElement)
              .toList();

      variants.add(StateVariantDescriptor(
        name: name,
        className: '$stateType${_capitalize(name)}',
        fields: fields,
      ));
    }

    StateVariantDescriptor? find(String name) {
      for (final v in variants) {
        if (v.name == name) return v;
      }
      return null;
    }

    final initial = find('initial');
    if (initial == null) {
      throw InvalidGenerationSourceError(
        '@StateManager(state: $stateType) requires the state model to declare '
        'an `initial` factory — it becomes the controller\'s starting state. Add '
        '`const factory $stateType.initial() = ${stateType}Initial;`.',
        element: element,
      );
    }

    // An `initial` variant with parameters can't be const-constructed by the
    // controller; the delegate must provide it through an `initialState`
    // getter instead.
    final initialFromDelegate = initial.fields.isNotEmpty;
    if (initialFromDelegate) {
      final hasInitialStateGetter = element.getters.any(
        (g) => g.name == 'initialState' && g.returnType.getDisplayString() == stateType,
      );
      if (!hasInitialStateGetter) {
        throw InvalidGenerationSourceError(
          '@StateManager(state: $stateType): the `initial` factory takes '
          'parameters, so the controller cannot const-construct it. Add '
          '`$stateType get initialState => $stateType.initial(...);` to '
          '$className — the generated controller will use it as the starting '
          'state.',
          element: element,
        );
      }
    }

    final loading = find('loading');
    final autoLoading = loading != null && loading.fields.isEmpty;

    final error = find('error');
    final autoError = error != null &&
        error.fields.length == 1 &&
        error.fields.first.isNamed &&
        error.fields.first.name == 'message' &&
        error.fields.first.type == 'String';

    for (final event in events) {
      if (!event.returnsState) {
        throw InvalidGenerationSourceError(
          '@Event ${event.name} must return $stateType (or Future<$stateType>) '
          'because ${className} runs in StateModel mode. Found a different '
          'return type.',
          element: element,
        );
      }
    }

    return StateManagerDescriptor(
      className: className,
      stateType: stateType,
      easyMode: false,
      logging: logging,
      autoLoading: autoLoading,
      autoError: autoError,
      initialVariant: 'initial',
      initialFromDelegate: initialFromDelegate,
      events: events,
      methods: methods,
      variants: variants,
      sourceUri: sourceUri,
      stateSourceUri: stateElement.library.uri.toString(),
    );
  }

  // ── Events ───────────────────────────────────────────────────────────────

  static EventDescriptor _describeEvent(
    MethodElement method,
    List<ParamDescriptor> params, {
    required bool easyMode,
    required String? stateType,
  }) {
    final annotation =
        ConstantReader(_eventChecker.firstAnnotationOfExact(method));

    Duration? readDuration(String field) {
      final value = annotation.peek(field);
      if (value == null || value.isNull) return null;
      final micros = value.objectValue.getField('_duration')?.toIntValue();
      return micros == null ? null : Duration(microseconds: micros);
    }

    final rawReturn = method.returnType;
    final isAsync =
        rawReturn.isDartAsyncFuture || rawReturn.isDartAsyncFutureOr;
    final unwrapped = _unwrapFuture(rawReturn);
    final isVoid = unwrapped is VoidType;

    if (!easyMode) {
      final returnsState = !isVoid &&
          unwrapped is InterfaceType &&
          unwrapped.getDisplayString() == stateType;
      return EventDescriptor(
        name: method.name ?? '',
        params: params,
        payloadType: null,
        isEither: false,
        eitherLeftType: null,
        returnsState: returnsState,
        isAsync: isAsync,
        debounce: readDuration('debounce'),
        throttle: readDuration('throttle'),
      );
    }

    String? payloadType;
    var isEither = false;
    String? eitherLeftType;

    if (!isVoid && unwrapped is InterfaceType) {
      if (unwrapped.element.name == 'Either' &&
          unwrapped.typeArguments.length == 2) {
        isEither = true;
        eitherLeftType = unwrapped.typeArguments[0].getDisplayString();
        payloadType = unwrapped.typeArguments[1].getDisplayString();
      } else {
        payloadType = unwrapped.getDisplayString();
      }
    } else if (!isVoid) {
      payloadType = unwrapped.getDisplayString();
    }

    return EventDescriptor(
      name: method.name ?? '',
      params: params,
      payloadType: payloadType,
      isEither: isEither,
      eitherLeftType: eitherLeftType,
      returnsState: false,
      isAsync: isAsync,
      debounce: readDuration('debounce'),
      throttle: readDuration('throttle'),
    );
  }

  static DartType _unwrapFuture(DartType type) {
    if ((type.isDartAsyncFuture || type.isDartAsyncFutureOr) &&
        type is InterfaceType &&
        type.typeArguments.isNotEmpty) {
      return type.typeArguments.first;
    }
    return type;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
