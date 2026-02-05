import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/feature/state_manager.dart';
import 'package:dragonfly/framework/feature/state_manager_provider.dart';

/// A widget that rebuilds when the state manager's state changes.
///
/// Example:
/// ```dart
/// StateManagerBuilder<CharacterStateManager, CharacterState>(
///   builder: (context, state) {
///     return state.when(
///       initial: () => const Text('Tap to load'),
///       loading: () => const CircularProgressIndicator(),
///       loaded: (character) => Text(character.name),
///       error: (message) => Text(message),
///     );
///   },
/// )
/// ```
class StateManagerBuilder<SM extends StateManager<S>, S> extends StatefulWidget {
  const StateManagerBuilder({
    super.key,
    this.stateManager,
    required this.builder,
    this.buildWhen,
  });

  /// The state manager to listen to. If null, uses the state manager from context.
  final SM? stateManager;

  /// The builder function called when state changes.
  final StateManagerWidgetBuilder<S> builder;

  /// Optional function to determine if the builder should be called.
  final StateManagerStateComparator<S>? buildWhen;

  @override
  State<StateManagerBuilder<SM, S>> createState() => _StateManagerBuilderState<SM, S>();
}

class _StateManagerBuilderState<SM extends StateManager<S>, S>
    extends State<StateManagerBuilder<SM, S>> {
  late SM _stateManager;
  late S _state;
  StreamSubscription<S>? _subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stateManager = widget.stateManager ?? context.stateManager<SM>();
    _state = _stateManager.state;
    _subscribe();
  }

  @override
  void didUpdateWidget(StateManagerBuilder<SM, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStateManager = widget.stateManager ?? context.stateManager<SM>();
    if (newStateManager != _stateManager) {
      _unsubscribe();
      _stateManager = newStateManager;
      _state = _stateManager.state;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _stateManager.stream.listen((state) {
      if (widget.buildWhen?.call(_state, state) ?? true) {
        setState(() => _state = state);
      } else {
        _state = state;
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _state);
  }
}

/// A widget that listens to state manager state changes and calls a listener.
///
/// Unlike [StateManagerBuilder], this doesn't rebuild - it's for side effects.
///
/// Example:
/// ```dart
/// StateManagerListener<CharacterStateManager, CharacterState>(
///   listener: (context, state) {
///     if (state is CharacterStateError) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(state.message)),
///       );
///     }
///   },
///   child: const CharacterView(),
/// )
/// ```
class StateManagerListener<SM extends StateManager<S>, S> extends StatefulWidget {
  const StateManagerListener({
    super.key,
    this.stateManager,
    required this.listener,
    this.listenWhen,
    required this.child,
  });

  /// The state manager to listen to. If null, uses the state manager from context.
  final SM? stateManager;

  /// The listener called when state changes.
  final void Function(BuildContext context, S state) listener;

  /// Optional function to determine if the listener should be called.
  final StateManagerStateComparator<S>? listenWhen;

  /// The child widget.
  final Widget child;

  @override
  State<StateManagerListener<SM, S>> createState() => _StateManagerListenerState<SM, S>();
}

class _StateManagerListenerState<SM extends StateManager<S>, S>
    extends State<StateManagerListener<SM, S>> {
  late SM _stateManager;
  late S _previousState;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stateManager = widget.stateManager ?? context.stateManager<SM>();
    _previousState = _stateManager.state;
    _subscribe();
  }

  @override
  void didUpdateWidget(StateManagerListener<SM, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStateManager = widget.stateManager ?? context.stateManager<SM>();
    if (newStateManager != _stateManager) {
      _unsubscribe();
      _stateManager = newStateManager;
      _previousState = _stateManager.state;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _stateManager.stream.listen((state) {
      if (widget.listenWhen?.call(_previousState, state) ?? true) {
        widget.listener(context, state);
      }
      _previousState = state;
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A widget that listens to state manager side effects.
///
/// Example:
/// ```dart
/// StateManagerSideEffectListener<CharacterStateManager>(
///   listener: (context, effect) {
///     if (effect is NavigateTo) {
///       Navigator.pushNamed(context, effect.route);
///     } else if (effect is ShowSnackbar) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(effect.message)),
///       );
///     }
///   },
///   child: const CharacterView(),
/// )
/// ```
class StateManagerSideEffectListener<SM extends StateManager<dynamic>>
    extends StatefulWidget {
  const StateManagerSideEffectListener({
    super.key,
    this.stateManager,
    required this.listener,
    required this.child,
  });

  /// The state manager to listen to. If null, uses the state manager from context.
  final SM? stateManager;

  /// The listener called when a side effect is emitted.
  final void Function(BuildContext context, StateManagerSideEffect effect) listener;

  /// The child widget.
  final Widget child;

  @override
  State<StateManagerSideEffectListener<SM>> createState() =>
      _StateManagerSideEffectListenerState<SM>();
}

class _StateManagerSideEffectListenerState<SM extends StateManager<dynamic>>
    extends State<StateManagerSideEffectListener<SM>> {
  late SM _stateManager;
  StreamSubscription<StateManagerSideEffect>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stateManager = widget.stateManager ?? context.stateManager<SM>();
    _subscribe();
  }

  @override
  void didUpdateWidget(StateManagerSideEffectListener<SM> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStateManager = widget.stateManager ?? context.stateManager<SM>();
    if (newStateManager != _stateManager) {
      _unsubscribe();
      _stateManager = newStateManager;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _stateManager.sideEffects.listen((effect) {
      widget.listener(context, effect);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Combines [StateManagerBuilder] and [StateManagerListener] into one widget.
class StateManagerConsumer<SM extends StateManager<S>, S> extends StatelessWidget {
  const StateManagerConsumer({
    super.key,
    this.stateManager,
    required this.builder,
    required this.listener,
    this.buildWhen,
    this.listenWhen,
  });

  final SM? stateManager;
  final StateManagerWidgetBuilder<S> builder;
  final void Function(BuildContext context, S state) listener;
  final StateManagerStateComparator<S>? buildWhen;
  final StateManagerStateComparator<S>? listenWhen;

  @override
  Widget build(BuildContext context) {
    return StateManagerListener<SM, S>(
      stateManager: stateManager,
      listener: listener,
      listenWhen: listenWhen,
      child: StateManagerBuilder<SM, S>(
        stateManager: stateManager,
        builder: builder,
        buildWhen: buildWhen,
      ),
    );
  }
}

/// Selects a specific part of the state and only rebuilds when it changes.
class StateManagerSelector<SM extends StateManager<S>, S, T> extends StatefulWidget {
  const StateManagerSelector({
    super.key,
    this.stateManager,
    required this.selector,
    required this.builder,
  });

  final SM? stateManager;
  final T Function(S state) selector;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<StateManagerSelector<SM, S, T>> createState() =>
      _StateManagerSelectorState<SM, S, T>();
}

class _StateManagerSelectorState<SM extends StateManager<S>, S, T>
    extends State<StateManagerSelector<SM, S, T>> {
  late SM _stateManager;
  late T _selectedValue;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stateManager = widget.stateManager ?? context.stateManager<SM>();
    _selectedValue = widget.selector(_stateManager.state);
    _subscribe();
  }

  @override
  void didUpdateWidget(StateManagerSelector<SM, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStateManager = widget.stateManager ?? context.stateManager<SM>();
    if (newStateManager != _stateManager) {
      _unsubscribe();
      _stateManager = newStateManager;
      _selectedValue = widget.selector(_stateManager.state);
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _stateManager.stream.listen((state) {
      final newValue = widget.selector(state);
      if (newValue != _selectedValue) {
        setState(() => _selectedValue = newValue);
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue);
  }
}

// Backwards compatibility aliases
@Deprecated('Use StateManagerBuilder instead')
typedef FeatureBuilder<F extends StateManager<S>, S> = StateManagerBuilder<F, S>;

@Deprecated('Use StateManagerListener instead')
typedef FeatureListener<F extends StateManager<S>, S> = StateManagerListener<F, S>;

@Deprecated('Use StateManagerSideEffectListener instead')
typedef FeatureSideEffectListener<F extends StateManager<dynamic>> = StateManagerSideEffectListener<F>;

@Deprecated('Use StateManagerConsumer instead')
typedef FeatureConsumer<F extends StateManager<S>, S> = StateManagerConsumer<F, S>;

@Deprecated('Use StateManagerSelector instead')
typedef FeatureSelector<F extends StateManager<S>, S, T> = StateManagerSelector<F, S, T>;
