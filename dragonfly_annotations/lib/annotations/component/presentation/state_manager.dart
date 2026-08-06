import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Marks a plain class as a Dragonfly state manager.
///
/// The annotated class holds only business logic. It has **no base class and
/// no mixin** — the generator produces:
///
/// - a controller (`$XController`) that owns the state, is registered in DI,
///   and wraps every [@Event] method with automatic `loading` / `error`
///   emission,
/// - a view mixin (`$X`) that a `@StateView` widget mixes in to dispatch events and
///   build from state,
/// - and, in easy mode, the sealed state class itself (`XState`).
///
/// ## Easy mode (no [state] argument)
///
/// The framework generates the sealed state class. Each [@Event] method name
/// becomes a state variant whose payload is the method's return type
/// (`Future<void>` events produce a zero-payload variant). Built-in variants
/// `initial`, `loading` and `error` are always present. `loading` is emitted
/// automatically before the event body runs; a thrown exception becomes the
/// `error` variant. A return of `Either<L, R>` is unwrapped: `Right` is the
/// payload, `Left` becomes `error`.
///
/// ```dart
/// @StateManager()
/// class UserStateManager {
///   const UserStateManager(this._getUserList);
///   final GetUserListUseCase _getUserList;
///
///   @Event()
///   Future<List<User>> initialize(UserSession session) async { ... }
///
///   // Plain method: callable from the view, emits nothing.
///   Future<void> saveUsers(User user) async { ... }
/// }
/// ```
///
/// ## StateModel mode ([state] argument)
///
/// Point [state] at a `@StateModel()` sealed class and [@Event] methods return
/// that state type directly; the returned value is emitted as-is. If the model
/// declares a zero-arg `loading` factory it is emitted automatically before the
/// event body runs, and if it declares an `error({required String message})`
/// factory a thrown exception is emitted through it. The model must declare a
/// zero-arg `initial` factory — it becomes the controller's starting state.
///
/// ```dart
/// @StateManager(state: CharacterState)
/// class CharacterStateManager {
///   const CharacterStateManager(this._getCharacters);
///   final GetCharactersUseCase _getCharacters;
///
///   @Event()
///   Future<CharacterState> fetchCharacter(int id) async {
///     final result = await _getCharacters(id);
///     return result.fold(
///       (err) => CharacterState.error(message: '$err'),
///       (char) => CharacterState.loaded(character: char),
///     );
///   }
/// }
/// ```
@immutable
@Target({TargetKind.classType})
class StateManager {
  /// Optional `@StateModel` type this manager drives. When omitted the state
  /// class is generated from the [@Event] methods (easy mode).
  final Type? state;

  /// Whether to register this state manager (and its controller) in the DI
  /// container. Defaults to `true`.
  final bool injectable;

  /// Whether to log state transitions through `DragonflyLogManager`.
  final bool logging;

  /// Optional DI scope for the registration.
  final String? scope;

  const StateManager({
    this.state,
    this.injectable = true,
    this.logging = false,
    this.scope,
  });
}

/// Marks a method of a `@StateManager` class as a state-emitting event.
///
/// The event's **name** becomes a state variant and its **return value**
/// becomes that variant's payload. The generated controller emits `loading`
/// before invoking the method and `error` if it throws — the method body never
/// calls `emit`.
///
/// Methods without this annotation are plain actions: the view can call them
/// (through the controller) but they emit no state.
@immutable
@Target({TargetKind.method})
class Event {
  /// Optional debounce applied by the generated controller before the event
  /// body runs.
  final Duration? debounce;

  /// Optional throttle window applied by the generated controller.
  final Duration? throttle;

  const Event({this.debounce, this.throttle});
}

/// Binds a widget to a `@StateManager` class.
///
/// The generator produces a mixin named after the state manager
/// (`$UserStateManager`) that flattens the whole API onto the widget:
///
/// ```dart
/// @StateView(UserStateManager)
/// class UserScreen extends StatelessWidget with $UserStateManager {
///   const UserScreen({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         when(
///           initialize: (users) => UserList(users),
///           loading: () => const Spinner(),
///           orElse: () => const SizedBox.shrink(),
///         ),
///         buildInitialize((users) => Text('${users.length}')),
///         TextButton(
///           onPressed: () => initialize(session),
///           child: const Text('reload'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// - `when(...)` rebuilds on every state change; all callbacks are optional
///   and `orElse` covers the unmatched variants.
/// - `build<Event>(...)` builds only while the state is that variant.
/// - `buildFor('event', ...)` is the string-keyed escape hatch (payload is
///   `dynamic`).
/// - Calling `initialize(session)` dispatches the event through the
///   controller; plain methods are forwarded untouched.
@immutable
@Target({TargetKind.classType})
class StateView {
  /// The `@StateManager` class this view is bound to.
  final Type stateManager;

  const StateView(this.stateManager);
}
