import 'dart:async';
import 'package:flutter/foundation.dart';

/// Type definition for event handler functions.
typedef EventHandler<E, S> = FutureOr<void> Function(E event, Emitter<S> emit);

/// Type definition for state emitter.
typedef Emitter<S> = void Function(S state);

/// Base class for all Dragonfly BLoCs.
///
/// A BLoC (Business Logic Component) manages state and handles events
/// in a reactive manner.
///
/// Example usage:
/// ```dart
/// class UserBloc extends DragonflyBlocBase<UserEvent, UserState> {
///   UserBloc() : super(const UserState.initial()) {
///     on<UserEventFetchUser>(_onFetchUser);
///     on<UserEventDeleteUser>(_onDeleteUser);
///   }
///
///   Future<void> _onFetchUser(
///     UserEventFetchUser event,
///     Emitter<UserState> emit,
///   ) async {
///     emit(const UserState.loading());
///     try {
///       final user = await userRepository.getUser(event.userId);
///       emit(UserState.loaded(user: user));
///     } catch (e) {
///       emit(UserState.error(message: e.toString()));
///     }
///   }
/// }
/// ```
abstract class DragonflyBlocBase<E, S> {
  /// Creates a new BLoC with the given initial state.
  DragonflyBlocBase(this._state) {
    _stateController = StreamController<S>.broadcast();
  }

  /// The current state of the BLoC.
  S _state;

  /// Stream controller for state changes.
  late final StreamController<S> _stateController;

  /// Map of event handlers.
  final Map<Type, EventHandler<dynamic, S>> _handlers = {};

  /// Whether the BLoC has been closed.
  bool _isClosed = false;

  /// The current state.
  S get state => _state;

  /// Stream of state changes.
  Stream<S> get stream => _stateController.stream;

  /// Whether the BLoC is closed.
  bool get isClosed => _isClosed;

  /// Registers an event handler for events of type [T].
  ///
  /// ```dart
  /// on<UserEventFetchUser>(_onFetchUser);
  /// ```
  void on<T extends E>(EventHandler<T, S> handler) {
    assert(
      !_handlers.containsKey(T),
      'on<$T> was called multiple times. '
      'There should only be a single event handler per event type.',
    );
    _handlers[T] = (event, emit) => handler(event as T, emit);
  }

  /// Adds an event to be processed by the BLoC.
  ///
  /// ```dart
  /// bloc.add(UserEvent.fetchUser(userId: 1));
  /// ```
  void add(E event) {
    if (_isClosed) {
      throw StateError('Cannot add events to a closed BLoC');
    }

    final handler = _handlers[event.runtimeType];
    if (handler == null) {
      throw StateError(
        'No handler registered for event type ${event.runtimeType}. '
        'Make sure to call on<${event.runtimeType}>() in the constructor.',
      );
    }

    _handleEvent(event, handler);
  }

  /// Internal method to handle events.
  Future<void> _handleEvent(
    E event,
    EventHandler<dynamic, S> handler,
  ) async {
    try {
      await handler(event, _emit);
    } catch (e, stackTrace) {
      onError(e, stackTrace);
    }
  }

  /// Emits a new state.
  void _emit(S newState) {
    if (_isClosed) return;
    if (_state == newState) return;

    _state = newState;
    _stateController.add(newState);
  }

  /// Called when an error occurs during event handling.
  ///
  /// Override this method to handle errors.
  @protected
  void onError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('Error in ${runtimeType}: $error\n$stackTrace');
    }
  }

  /// Closes the BLoC and releases resources.
  @mustCallSuper
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _stateController.close();
  }
}

/// Extension methods for DragonflyBlocBase.
extension DragonflyBlocExtension<E, S> on DragonflyBlocBase<E, S> {
  /// Listens to state changes.
  StreamSubscription<S> listen(
    void Function(S state) onState, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onState,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
