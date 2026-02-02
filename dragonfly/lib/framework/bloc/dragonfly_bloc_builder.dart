import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/bloc/dragonfly_bloc.dart';
import 'package:dragonfly/framework/bloc/dragonfly_bloc_provider.dart';

/// Signature for the builder function used by [DragonflyBlocBuilder].
typedef DragonflyBlocWidgetBuilder<S> = Widget Function(
  BuildContext context,
  S state,
);

/// Signature for the buildWhen function.
typedef DragonflyBlocBuilderCondition<S> = bool Function(
  S previous,
  S current,
);

/// A widget that rebuilds when the BLoC's state changes.
///
/// Usage:
/// ```dart
/// DragonflyBlocBuilder<UserBloc, UserState>(
///   builder: (context, state) {
///     return state.when(
///       initial: () => Text('Welcome'),
///       loading: () => CircularProgressIndicator(),
///       loaded: (user) => Text(user.name),
///       error: (message) => Text(message),
///     );
///   },
/// )
/// ```
class DragonflyBlocBuilder<B extends DragonflyBlocBase<dynamic, S>, S>
    extends StatefulWidget {
  /// Creates a [DragonflyBlocBuilder].
  const DragonflyBlocBuilder({
    super.key,
    this.bloc,
    required this.builder,
    this.buildWhen,
  });

  /// The BLoC to listen to. If null, it will be obtained from the context.
  final B? bloc;

  /// The builder function called when the state changes.
  final DragonflyBlocWidgetBuilder<S> builder;

  /// Optional condition to determine if the widget should rebuild.
  ///
  /// If null, the widget rebuilds on every state change.
  final DragonflyBlocBuilderCondition<S>? buildWhen;

  @override
  State<DragonflyBlocBuilder<B, S>> createState() =>
      _DragonflyBlocBuilderState<B, S>();
}

class _DragonflyBlocBuilderState<B extends DragonflyBlocBase<dynamic, S>, S>
    extends State<DragonflyBlocBuilder<B, S>> {
  B? _bloc;
  S? _state;
  StreamSubscription<S>? _subscription;

  B get bloc => _bloc!;
  S get state => _state!;

  @override
  void initState() {
    super.initState();
    // If bloc is provided directly, use it
    if (widget.bloc != null) {
      _bloc = widget.bloc;
      _state = _bloc!.state;
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If bloc was not provided, get it from context here (safe to call)
    if (widget.bloc == null) {
      final newBloc = DragonflyBlocProvider.of<B>(context);
      if (_bloc != newBloc) {
        _unsubscribe();
        _bloc = newBloc;
        _state = _bloc!.state;
        _subscribe();
      }
    }
  }

  @override
  void didUpdateWidget(DragonflyBlocBuilder<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? _bloc;
    final currentBloc = widget.bloc ?? DragonflyBlocProvider.of<B>(context);
    if (oldBloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _state = _bloc!.state;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc?.stream.listen((newState) {
      if (widget.buildWhen?.call(_state!, newState) ?? true) {
        setState(() {
          _state = newState;
        });
      } else {
        _state = newState;
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_bloc == null || _state == null) {
      // Return empty container while waiting for didChangeDependencies
      return const SizedBox.shrink();
    }
    return widget.builder(context, state);
  }
}

/// A widget that listens to state changes without rebuilding.
///
/// Useful for showing dialogs, snackbars, or navigation.
///
/// ```dart
/// DragonflyBlocListener<UserBloc, UserState>(
///   listener: (context, state) {
///     state.maybeWhen(
///       error: (message) => ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(message)),
///       ),
///       orElse: () {},
///     );
///   },
///   child: MyWidget(),
/// )
/// ```
class DragonflyBlocListener<B extends DragonflyBlocBase<dynamic, S>, S>
    extends StatefulWidget {
  /// Creates a [DragonflyBlocListener].
  const DragonflyBlocListener({
    super.key,
    this.bloc,
    required this.listener,
    this.listenWhen,
    required this.child,
  });

  /// The BLoC to listen to. If null, it will be obtained from the context.
  final B? bloc;

  /// The listener function called when the state changes.
  final void Function(BuildContext context, S state) listener;

  /// Optional condition to determine if the listener should be called.
  final DragonflyBlocBuilderCondition<S>? listenWhen;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<DragonflyBlocListener<B, S>> createState() =>
      _DragonflyBlocListenerState<B, S>();
}

class _DragonflyBlocListenerState<B extends DragonflyBlocBase<dynamic, S>, S>
    extends State<DragonflyBlocListener<B, S>> {
  B? _bloc;
  S? _previousState;
  StreamSubscription<S>? _subscription;

  @override
  void initState() {
    super.initState();
    // If bloc is provided directly, use it
    if (widget.bloc != null) {
      _bloc = widget.bloc;
      _previousState = _bloc!.state;
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If bloc was not provided, get it from context here (safe to call)
    if (widget.bloc == null) {
      final newBloc = DragonflyBlocProvider.of<B>(context);
      if (_bloc != newBloc) {
        _unsubscribe();
        _bloc = newBloc;
        _previousState = _bloc!.state;
        _subscribe();
      }
    }
  }

  @override
  void didUpdateWidget(DragonflyBlocListener<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? _bloc;
    final currentBloc = widget.bloc ?? DragonflyBlocProvider.of<B>(context);
    if (oldBloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _previousState = _bloc!.state;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc?.stream.listen((state) {
      if (widget.listenWhen?.call(_previousState!, state) ?? true) {
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
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Combines [DragonflyBlocBuilder] and [DragonflyBlocListener] into one widget.
class DragonflyBlocConsumer<B extends DragonflyBlocBase<dynamic, S>, S>
    extends StatelessWidget {
  /// Creates a [DragonflyBlocConsumer].
  const DragonflyBlocConsumer({
    super.key,
    this.bloc,
    required this.builder,
    required this.listener,
    this.buildWhen,
    this.listenWhen,
  });

  /// The BLoC to use. If null, it will be obtained from the context.
  final B? bloc;

  /// The builder function called when the state changes.
  final DragonflyBlocWidgetBuilder<S> builder;

  /// The listener function called when the state changes.
  final void Function(BuildContext context, S state) listener;

  /// Optional condition to determine if the widget should rebuild.
  final DragonflyBlocBuilderCondition<S>? buildWhen;

  /// Optional condition to determine if the listener should be called.
  final DragonflyBlocBuilderCondition<S>? listenWhen;

  @override
  Widget build(BuildContext context) {
    return DragonflyBlocListener<B, S>(
      bloc: bloc,
      listener: listener,
      listenWhen: listenWhen,
      child: DragonflyBlocBuilder<B, S>(
        bloc: bloc,
        builder: builder,
        buildWhen: buildWhen,
      ),
    );
  }
}
