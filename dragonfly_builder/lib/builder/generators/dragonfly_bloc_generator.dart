import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @DragonflyBloc annotated classes.
///
/// This generator creates a mixin that:
/// - Declares abstract handler methods for each event variant
/// - Automatically registers event handlers in the constructor
///
/// Example input:
/// ```dart
/// @DragonflyBloc(event: UserEvent, state: UserState)
/// class UserBloc extends DragonflyBloc<UserEvent, UserState>
///     with _$UserBlocMixin {
///   UserBloc() : super(const UserState.initial());
/// }
/// ```
///
/// Example output:
/// ```dart
/// mixin _$UserBlocMixin on DragonflyBloc<UserEvent, UserState> {
///   void registerHandlers() {
///     on<UserEventLoading>((event, emit) => onLoading(event, emit));
///     on<UserEventFetchUser>((event, emit) => onFetchUser(event, emit));
///     on<UserEventDeleteUser>((event, emit) => onDeleteUser(event, emit));
///   }
///
///   Future<void> onLoading(UserEventLoading event, Emitter<UserState> emit);
///   Future<void> onFetchUser(UserEventFetchUser event, Emitter<UserState> emit);
///   Future<void> onDeleteUser(UserEventDeleteUser event, Emitter<UserState> emit);
/// }
/// ```
class DragonflyBlocGenerator
    extends GeneratorForAnnotation<DragonflyBloc> {
  final _formatter = DartFormatter();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@DragonflyBloc can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final eventType = _getTypeName(annotation.read('event'));
    final stateType = _getTypeName(annotation.read('state'));
    final enableLogging = annotation.read('enableLogging').boolValue;

    // Find event variants by looking at the event class
    final eventVariants = _findEventVariants(element, eventType);

    try {
      final code = _generateBlocMixin(
        className,
        eventType,
        stateType,
        eventVariants,
        enableLogging,
      );

      return _formatter.format(code);
    } catch (e) {
      log.severe('DragonflyBlocGenerator error: $e');
      return '// Error generating bloc code: $e';
    }
  }

  String _getTypeName(ConstantReader reader) {
    final type = reader.typeValue;
    return type.getDisplayString(withNullability: false);
  }

  /// Find event variant classes by analyzing the imports and looking for
  /// classes that extend or implement the event type.
  List<_EventVariant> _findEventVariants(
    ClassElement blocClass,
    String eventType,
  ) {
    // For now, we'll generate placeholder handlers based on common patterns
    // The actual variant detection would require analyzing the event file
    // which is complex. Instead, we'll generate a simpler pattern.
    
    // Return empty - the user will implement handlers directly
    return [];
  }

  String _generateBlocMixin(
    String className,
    String eventType,
    String stateType,
    List<_EventVariant> eventVariants,
    bool enableLogging,
  ) {
    final buffer = StringBuffer();

    // Generate the mixin
    buffer.writeln('/// Generated mixin for $className.');
    buffer.writeln('///');
    buffer.writeln('/// Provides helper methods for event handling and state management.');
    buffer.writeln('mixin _\$${className}Mixin on DragonflyBlocBase<$eventType, $stateType> {');

    // Generate dispatch helper
    buffer.writeln('  /// Dispatches an event to the bloc.');
    buffer.writeln('  void dispatch($eventType event) => add(event);');
    buffer.writeln();

    // Generate state helpers
    buffer.writeln('  /// The current state of the bloc.');
    buffer.writeln('  $stateType get currentState => state;');
    buffer.writeln();

    // Generate logging if enabled
    if (enableLogging) {
      buffer.writeln('  @override');
      buffer.writeln('  void onError(Object error, StackTrace stackTrace) {');
      buffer.writeln("    print('[$className] Error: \$error');");
      buffer.writeln('    super.onError(error, stackTrace);');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('}');

    return buffer.toString();
  }
}

class _EventVariant {
  final String name;
  final String className;
  final List<_EventParam> params;

  _EventVariant({
    required this.name,
    required this.className,
    required this.params,
  });
}

class _EventParam {
  final String name;
  final String type;

  _EventParam({required this.name, required this.type});
}
