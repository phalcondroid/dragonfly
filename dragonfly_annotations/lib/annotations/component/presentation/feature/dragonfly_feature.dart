import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Annotation for creating a Dragonfly Feature.
///
/// A Feature combines state management, intents (user actions), and
/// side effects into a single, cohesive unit.
///
/// Example:
/// ```dart
/// @DragonflyFeature()
/// class CharacterFeature extends Feature<CharacterFeature, CharacterState> {
///   @InitialState()
///   CharacterState get initialState => const CharacterState.initial();
///
///   @Intent()
///   Future<void> fetchCharacter(int id) async {
///     emit(const CharacterState.loading());
///     final result = await useCase<GetCharacterUseCase>().call(id);
///     result.fold(
///       (err) => emit(CharacterState.error(err.message)),
///       (char) => emit(CharacterState.loaded(char)),
///     );
///   }
/// }
/// ```
@immutable
class DragonflyFeature {
  /// Whether to automatically register this feature in the DI container.
  final bool injectable;

  /// Whether to enable state change logging.
  final bool logging;

  /// Optional scope for DI registration.
  final String? scope;

  /// Order position for DI registration.
  final int order;

  /// The state type for this feature.
  final Type? state;

  const DragonflyFeature({
    this.injectable = true,
    this.logging = false,
    this.scope,
    this.order = 100,
    this.state,
  });
}

/// Marks a getter as the initial state for a Feature.
///
/// Example:
/// ```dart
/// @InitialState()
/// CharacterState get initialState => const CharacterState.initial();
/// ```
@immutable
@Target({TargetKind.getter, TargetKind.field})
class InitialState {
  const InitialState();
}

/// Marks a method as a user action in a Feature.
///
/// User actions are triggered from the UI and can modify state.
///
/// Example:
/// ```dart
/// @FeatureAction()
/// Future<void> fetchCharacter(int id) async {
///   emit(const CharacterState.loading());
///   // ...
/// }
///
/// @FeatureAction(debounce: Duration(milliseconds: 300))
/// Future<void> search(String query) async { ... }
/// ```
@immutable
@Target({TargetKind.method})
class FeatureAction {
  /// Optional debounce duration for this action.
  final Duration? debounce;

  /// Optional throttle duration for this action.
  final Duration? throttle;

  /// Whether this action should be logged.
  final bool log;

  const FeatureAction({
    this.debounce,
    this.throttle,
    this.log = true,
  });
}

/// Marks a method as a SideEffect in a Feature.
///
/// Side effects are actions that don't modify state but interact
/// with the outside world (navigation, dialogs, snackbars, etc.)
///
/// Example:
/// ```dart
/// @SideEffect()
/// void showError(String message) {
///   sideEffect(ShowSnackbar(message));
/// }
/// ```
@immutable
@Target({TargetKind.method})
class SideEffect {
  const SideEffect();
}

/// Marks a getter as a Computed value derived from state.
///
/// Computed values are automatically recalculated when state changes.
///
/// Example:
/// ```dart
/// @Computed()
/// bool get isValid => state.name.isNotEmpty && state.email.contains('@');
///
/// @Computed()
/// int get itemCount => state.items.length;
/// ```
@immutable
@Target({TargetKind.getter})
class Computed {
  const Computed();
}

/// Marks a state slot for features with multiple independent state sections.
///
/// Example:
/// ```dart
/// @StateSlot('user')
/// UserSlotState get userState => _userState;
/// ```
@immutable
@Target({TargetKind.getter, TargetKind.field})
class StateSlot {
  final String name;
  const StateSlot(this.name);
}
