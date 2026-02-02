import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';

/// Base class for side effects that can be emitted from a Feature.
abstract class FeatureSideEffect {
  const FeatureSideEffect();
}

/// Navigation side effect.
class NavigateTo extends FeatureSideEffect {
  final String route;
  final Object? arguments;
  final bool replace;

  const NavigateTo(this.route, {this.arguments, this.replace = false});
}

/// Show snackbar side effect.
class ShowSnackbar extends FeatureSideEffect {
  final String message;
  final Duration duration;

  const ShowSnackbar(this.message, {this.duration = const Duration(seconds: 3)});
}

/// Show dialog side effect.
class ShowDialog extends FeatureSideEffect {
  final Widget Function(BuildContext context) builder;

  const ShowDialog(this.builder);
}

/// Pop navigation side effect.
class Pop extends FeatureSideEffect {
  final Object? result;
  const Pop([this.result]);
}

/// Base class for all Dragonfly Features.
///
/// A Feature encapsulates state management, user intents, and side effects
/// into a cohesive unit with minimal boilerplate.
///
/// Example:
/// ```dart
/// class CharacterFeature extends Feature<CharacterState> {
///   CharacterFeature() : super(const CharacterState.initial());
///
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
abstract class Feature<S> {
  Feature(this._state) {
    _stateController = StreamController<S>.broadcast();
    _sideEffectController = StreamController<FeatureSideEffect>.broadcast();
    _init();
  }

  late final StreamController<S> _stateController;
  late final StreamController<FeatureSideEffect> _sideEffectController;
  S _state;

  /// The current state of this feature.
  S get state => _state;

  /// Stream of state changes.
  Stream<S> get stream => _stateController.stream;

  /// Stream of side effects.
  Stream<FeatureSideEffect> get sideEffects => _sideEffectController.stream;

  /// Whether this feature has been disposed.
  bool _disposed = false;
  bool get isDisposed => _disposed;

  /// Logging enabled flag (set by generator).
  bool get loggingEnabled => false;

  /// Called when the feature is initialized.
  /// Override to perform setup logic.
  void _init() {
    onInit();
  }

  /// Override to perform initialization logic.
  @protected
  void onInit() {}

  /// Emits a new state.
  @protected
  void emit(S newState) {
    if (_disposed) return;

    if (loggingEnabled) {
      // ignore: avoid_print
      print('[${runtimeType.toString()}] State: $_state -> $newState');
    }

    _state = newState;
    _stateController.add(newState);
  }

  /// Emits a side effect.
  @protected
  void sideEffect(FeatureSideEffect effect) {
    if (_disposed) return;

    if (loggingEnabled) {
      // ignore: avoid_print
      print('[${runtimeType.toString()}] SideEffect: $effect');
    }

    _sideEffectController.add(effect);
  }

  /// Gets a use case from the DI container.
  T useCase<T extends Object>() => DragonflyContainer.I.get<T>();

  /// Gets a dependency from the DI container.
  T get<T extends Object>({String? instanceName}) =>
      DragonflyContainer.I.get<T>(instanceName: instanceName);

  /// Disposes this feature and releases resources.
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    onDispose();
    _stateController.close();
    _sideEffectController.close();
  }

  /// Override to perform cleanup logic.
  @protected
  void onDispose() {}
}

/// Typedef for a state listener callback.
typedef FeatureStateListener<S> = void Function(S state);

/// Typedef for a side effect callback.
typedef SideEffectCallback = void Function(FeatureSideEffect effect);

/// Typedef for a state builder callback.
typedef FeatureWidgetBuilder<S> = Widget Function(BuildContext context, S state);

/// Typedef for state comparison.
typedef FeatureStateComparator<S> = bool Function(S previous, S current);
