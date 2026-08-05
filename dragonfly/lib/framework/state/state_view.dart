import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:dragonfly/framework/feature/state_manager.dart';
import 'package:dragonfly/framework/feature/state_manager_provider.dart';

/// Base class for a screen driven by a [StateManager].
///
/// Removes the `StateManagerBuilder` + `context.stateManager<SM>()` boilerplate:
/// implement [buildState] and receive both the current state and the manager.
///
/// ```dart
/// class CharacterScreen extends StateView<CharacterFeature, CharacterState> {
///   const CharacterScreen({super.key});
///
///   @override
///   Widget buildState(BuildContext context, CharacterState state,
///       CharacterFeature manager) {
///     return Scaffold(
///       appBar: AppBar(actions: [
///         IconButton(
///           icon: const Icon(Icons.refresh),
///           onPressed: manager.fetchCharacters,
///         ),
///       ]),
///       body: state.when(
///         initial: () => const SizedBox.shrink(),
///         loading: () => const CircularProgressIndicator(),
///         loaded: (character) => Text(character.name),
///         error: (message) => Text(message),
///       ),
///     );
///   }
/// }
/// ```
///
/// Override [buildWhen] to skip rebuilds, or use [StateSelector] for a subtree
/// that depends on one slice of the state.
abstract class StateView<SM extends StateManager<S>, S> extends StatelessWidget {
  const StateView({super.key});

  /// Builds the screen for [state].
  Widget buildState(BuildContext context, S state, SM manager);

  /// Return `false` to keep the previous frame instead of rebuilding.
  bool buildWhen(S previous, S current) => true;

  @override
  Widget build(BuildContext context) {
    final manager = StateManagerProvider.of<SM>(context);
    return _StateStreamBuilder<S>(
      manager: manager,
      buildWhen: buildWhen,
      builder: (context, state) => buildState(context, state, manager),
    );
  }
}

/// Rebuilds only when [selector] produces a different value.
///
/// Use this to keep an expensive subtree stable while unrelated parts of the
/// state change:
///
/// ```dart
/// StateSelector<CartFeature, CartState, int>(
///   selector: (state) => state.items.length,
///   builder: (context, count) => Badge(count: count),
/// )
/// ```
class StateSelector<SM extends StateManager<S>, S, T> extends StatefulWidget {
  const StateSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.manager,
  });

  /// Extracts the value this subtree depends on.
  final T Function(S state) selector;

  /// Builds from the selected value.
  final Widget Function(BuildContext context, T value) builder;

  /// Explicit manager; defaults to the nearest provided one.
  final SM? manager;

  @override
  State<StateSelector<SM, S, T>> createState() =>
      _StateSelectorState<SM, S, T>();
}

class _StateSelectorState<SM extends StateManager<S>, S, T>
    extends State<StateSelector<SM, S, T>> {
  late SM _manager;
  late T _value;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = widget.manager ?? StateManagerProvider.of<SM>(context);
    if (_subscription != null && identical(manager, _manager)) return;

    _subscription?.cancel();
    _manager = manager;
    _value = widget.selector(_manager.state);
    _subscription = _manager.stream.listen((state) {
      final next = widget.selector(state);
      if (next == _value) return;
      if (!mounted) return;
      setState(() => _value = next);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

/// Shared stream plumbing for [StateView].
class _StateStreamBuilder<S> extends StatefulWidget {
  const _StateStreamBuilder({
    super.key,
    required this.manager,
    required this.builder,
    required this.buildWhen,
  });

  final StateManager<S> manager;
  final Widget Function(BuildContext context, S state) builder;
  final bool Function(S previous, S current) buildWhen;

  @override
  State<_StateStreamBuilder<S>> createState() => _StateStreamBuilderState<S>();
}

class _StateStreamBuilderState<S> extends State<_StateStreamBuilder<S>> {
  late S _state;
  StreamSubscription<S>? _subscription;

  @override
  void initState() {
    super.initState();
    _state = widget.manager.state;
    _listen();
  }

  @override
  void didUpdateWidget(_StateStreamBuilder<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.manager, widget.manager)) {
      _subscription?.cancel();
      _state = widget.manager.state;
      _listen();
    }
  }

  void _listen() {
    _subscription = widget.manager.stream.listen((next) {
      if (!mounted) return;
      if (!widget.buildWhen(_state, next)) {
        _state = next;
        return;
      }
      setState(() => _state = next);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
