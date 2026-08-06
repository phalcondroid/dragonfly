import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:dragonfly/framework/di/dragonfly_container.dart';
import 'package:dragonfly/framework/logging/dragonfly_log_manager.dart';
import 'package:dragonfly/framework/state/action_scheduler.dart';

/// Base class for generated state controllers.
///
/// A controller owns the state of a `@StateManager` class: it holds the
/// current state, exposes it as a broadcast stream, and is the object views
/// talk to. You never subclass this by hand — the state manager generator
/// emits a concrete `$XController` per annotated class, and that generated
/// subclass is what gets registered in the DI container.
///
/// The controller itself is deliberately small:
///
/// - [emit] replaces the state and notifies listeners.
/// - [schedule] applies a debounce/throttle policy to an event dispatch
///   (this is what makes `@Event(debounce: …)` / `@Event(throttle: …)` work).
/// - [dispose] cancels every pending dispatch and closes the stream. The DI
///   registration wires this to the container's disposal.
abstract class DragonflyController<S> {
  /// Creates a controller holding [initial] as its starting state.
  DragonflyController(S initial)
      : _state = initial,
        _stateController = StreamController<S>.broadcast() {
    if (loggingEnabled) {
      _log.viewInit(viewName: controllerName, initialState: _state.toString());
    }
  }

  late final StreamController<S> _stateController;
  S _state;
  bool _disposed = false;

  /// Debounce/throttle scheduler backing [schedule].
  final ActionScheduler _scheduler = ActionScheduler();

  /// The current state.
  S get state => _state;

  /// Stream of state changes, suitable for a `DragonflyStateBuilder`.
  Stream<S> get stream => _stateController.stream;

  /// Whether [dispose] has run.
  bool get isDisposed => _disposed;

  /// Whether state transitions are logged. Overridden by generated code when
  /// the `@StateManager` annotation sets `logging: true`.
  bool get loggingEnabled => false;

  /// The name used in log output; defaults to the runtime type name.
  String get controllerName => runtimeType.toString();

  DragonflyLogManager get _log => DragonflyLogManager.instance;

  /// Replaces the state and notifies listeners. No-op after [dispose].
  @protected
  void emit(S next) {
    if (_disposed) return;

    if (loggingEnabled) {
      _log.viewStateChange(
        viewName: controllerName,
        previousState: _state.toString(),
        newState: next.toString(),
      );
    }

    _state = next;
    _stateController.add(next);
  }

  /// Runs [body] under the debounce/throttle policy declared for an event.
  ///
  /// Generated dispatchers route through here when the `@Event` annotation
  /// declares `debounce` or `throttle`. Every pending call is cancelled on
  /// [dispose], so a debounced event can never fire against a disposed
  /// controller. Returns `false` when the call was dropped by a throttle gate.
  bool schedule(
    String key,
    void Function() body, {
    Duration? debounce,
    Duration? throttle,
  }) {
    if (_disposed) return false;
    return _scheduler.run(key, body, debounce: debounce, throttle: throttle);
  }

  /// Cancels a pending debounced dispatch and reopens its throttle gate.
  void cancelScheduled(String key) => _scheduler.cancel(key);

  /// Runs a pending debounced dispatch now rather than waiting out its delay.
  void flushScheduled(String key) => _scheduler.flush(key);

  /// Whether [key] currently has a debounced dispatch waiting to fire.
  bool isScheduledPending(String key) => _scheduler.isPending(key);

  /// Resolves a dependency from the DI container. Convenience for hand-written
  /// helpers layered on top of generated controllers.
  T get<T extends Object>({String? instanceName}) =>
      DragonflyContainer.I.get<T>(instanceName: instanceName);

  /// Cancels pending dispatches and closes the state stream. Idempotent.
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    if (loggingEnabled) {
      _log.viewDispose(viewName: controllerName);
    }

    _scheduler.dispose();
    _stateController.close();
  }
}
