import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';
import 'package:dragonfly/framework/logging/dragonfly_log_manager.dart';

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

  @override
  String toString() => 'NavigateTo($route${replace ? ', replace: true' : ''})';
}

/// Show snackbar side effect.
class ShowSnackbar extends FeatureSideEffect {
  final String message;
  final Duration duration;

  const ShowSnackbar(this.message,
      {this.duration = const Duration(seconds: 3)});

  @override
  String toString() => 'ShowSnackbar("$message")';
}

/// Show dialog side effect.
class ShowDialog extends FeatureSideEffect {
  final Widget Function(BuildContext context) builder;

  const ShowDialog(this.builder);

  @override
  String toString() => 'ShowDialog(...)';
}

/// Pop navigation side effect.
class Pop extends FeatureSideEffect {
  final Object? result;
  const Pop([this.result]);

  @override
  String toString() => 'Pop(${result ?? ''})';
}

/// Base class for all Dragonfly Views (Features).
///
/// A Feature encapsulates state management, user actions, side effects,
/// and subscriptions into a cohesive unit with minimal boilerplate.
///
/// Example:
/// ```dart
/// @DragonflyView(logging: true)
/// class CharacterFeature extends Feature<CharacterState> {
///   CharacterFeature() : super(const CharacterState.initial());
///
///   @ViewAction()
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

  /// Active subscriptions managed by this feature.
  final Map<String, StreamSubscription> _subscriptions = {};

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

  /// Logger instance
  DragonflyLogManager get _log => DragonflyLogManager.instance;

  /// The name of this view for logging.
  String get _viewName => runtimeType.toString();

  /// Returns true if a subscription with the given key exists.
  bool hasSubscription(String key) => _subscriptions.containsKey(key);

  /// Returns the list of active subscription keys.
  List<String> get activeSubscriptions => _subscriptions.keys.toList();

  /// Called when the feature is initialized.
  void _init() {
    if (loggingEnabled) {
      _log.viewInit(viewName: _viewName, initialState: _state.toString());
    }
    onInit();
  }

  /// Override to perform initialization logic.
  @protected
  void onInit() {}

  /// Logs the start of a view action.
  @protected
  void logActionStart(String actionName, [Map<String, dynamic>? params]) {
    if (loggingEnabled) {
      _log.viewActionStart(
        viewName: _viewName,
        actionName: actionName,
        params: params,
      );
    }
  }

  /// Logs the end of a view action.
  @protected
  void logActionEnd(String actionName,
      {int? durationMs, bool success = true, String? error}) {
    if (loggingEnabled) {
      _log.viewActionEnd(
        viewName: _viewName,
        actionName: actionName,
        durationMs: durationMs,
        success: success,
        error: error,
      );
    }
  }

  /// Logs a step within an action.
  @protected
  void logStep(String step, [Map<String, dynamic>? data]) {
    if (loggingEnabled) {
      _log.viewStep(viewName: _viewName, step: step, data: data);
    }
  }

  /// Emits a new state.
  @protected
  void emit(S newState) {
    if (_disposed) return;

    if (loggingEnabled) {
      _log.viewStateChange(
        viewName: _viewName,
        previousState: _state.toString(),
        newState: newState.toString(),
      );
    }

    _state = newState;
    _stateController.add(newState);
  }

  /// Emits a side effect.
  @protected
  void sideEffect(FeatureSideEffect effect) {
    if (_disposed) return;

    if (loggingEnabled) {
      _log.viewSideEffect(viewName: _viewName, effect: effect.toString());
    }

    _sideEffectController.add(effect);
  }

  /// Subscribe to a stream and manage the subscription lifecycle.
  @protected
  void subscribe<T>(
    String key,
    Stream<T> stream, {
    required void Function(T data) onData,
    void Function(Object error)? onError,
    void Function()? onDone,
    bool cancelOnError = false,
  }) {
    cancelSubscription(key);

    if (loggingEnabled) {
      _log.viewSubscribe(viewName: _viewName, subscriptionKey: key);
    }

    _subscriptions[key] = stream.listen(
      (data) {
        if (!_disposed) {
          onData(data);
        }
      },
      onError: (error) {
        if (!_disposed) {
          if (loggingEnabled) {
            _log.viewSubscriptionError(
              viewName: _viewName,
              subscriptionKey: key,
              error: error.toString(),
            );
          }
          onError?.call(error);
        }
      },
      onDone: () {
        if (!_disposed) {
          if (loggingEnabled) {
            _log.viewSubscriptionDone(
                viewName: _viewName, subscriptionKey: key);
          }
          _subscriptions.remove(key);
          onDone?.call();
        }
      },
      cancelOnError: cancelOnError,
    );
  }

  /// Subscribe to an Either stream (common pattern with use cases).
  @protected
  void subscribeEither<L, R>(
    String key,
    Stream<dynamic> stream, {
    required void Function(R data) onRight,
    void Function(L error)? onLeft,
    void Function()? onDone,
  }) {
    subscribe<dynamic>(
      key,
      stream,
      onData: (either) {
        if (either.isRight) {
          onRight(either.getOrElse(() => null) as R);
        } else if (onLeft != null) {
          onLeft(either.fold((l) => l, (_) => null) as L);
        }
      },
      onError: (error) {
        onLeft?.call(error as L);
      },
      onDone: onDone,
    );
  }

  /// Cancel a specific subscription by key.
  @protected
  void cancelSubscription(String key) {
    final subscription = _subscriptions.remove(key);
    if (subscription != null) {
      if (loggingEnabled) {
        _log.viewCancelSubscription(viewName: _viewName, subscriptionKey: key);
      }
      subscription.cancel();
    }
  }

  /// Cancel all active subscriptions.
  @protected
  void cancelAllSubscriptions() {
    if (loggingEnabled && _subscriptions.isNotEmpty) {
      _log.info(
        'Cancelling all subscriptions (${_subscriptions.length})',
        source: _viewName,
      );
    }
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Pause a specific subscription.
  @protected
  void pauseSubscription(String key) {
    _subscriptions[key]?.pause();
  }

  /// Resume a specific subscription.
  @protected
  void resumeSubscription(String key) {
    _subscriptions[key]?.resume();
  }

  /// Gets a use case from the DI container.
  T useCase<T extends Object>() {
    if (loggingEnabled) {
      _log.viewUseCase(viewName: _viewName, useCaseName: T.toString());
    }
    return DragonflyContainer.I.get<T>();
  }

  /// Gets a dependency from the DI container.
  T get<T extends Object>({String? instanceName}) =>
      DragonflyContainer.I.get<T>(instanceName: instanceName);

  /// Disposes this feature and releases resources.
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    if (loggingEnabled) {
      _log.viewDispose(viewName: _viewName);
    }

    cancelAllSubscriptions();
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
typedef FeatureWidgetBuilder<S> = Widget Function(
    BuildContext context, S state);

/// Typedef for state comparison.
typedef FeatureStateComparator<S> = bool Function(S previous, S current);
