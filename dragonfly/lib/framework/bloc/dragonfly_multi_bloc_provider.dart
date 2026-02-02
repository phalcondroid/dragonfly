import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/bloc/dragonfly_bloc.dart';
import 'package:dragonfly/framework/bloc/dragonfly_bloc_provider.dart';

/// A widget that provides multiple BLoCs to its descendants.
///
/// Usage:
/// ```dart
/// DragonflyMultiBlocProvider(
///   providers: [
///     DragonflyBlocProvider<UserBloc>(create: (context) => UserBloc()),
///     DragonflyBlocProvider<SettingsBloc>(create: (context) => SettingsBloc()),
///   ],
///   child: MyApp(),
/// )
/// ```
class DragonflyMultiBlocProvider extends StatelessWidget {
  /// Creates a [DragonflyMultiBlocProvider].
  const DragonflyMultiBlocProvider({
    super.key,
    required this.providers,
    required this.child,
  });

  /// The list of BLoC providers.
  final List<DragonflyBlocProvider<DragonflyBlocBase<dynamic, dynamic>>> providers;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    for (final provider in providers.reversed) {
      result = DragonflyBlocProvider(
        create: provider.create,
        lazy: provider.lazy,
        child: result,
      );
    }

    return result;
  }
}

/// A widget that listens to multiple BLoCs.
///
/// Usage:
/// ```dart
/// DragonflyMultiBlocListener(
///   listeners: [
///     BlocListenerSingle<UserBloc, UserState>(
///       listener: (context, state) { ... },
///       child: const SizedBox.shrink(),
///     ),
///   ],
///   child: MyWidget(),
/// )
/// ```
class DragonflyMultiBlocListener extends StatelessWidget {
  /// Creates a [DragonflyMultiBlocListener].
  const DragonflyMultiBlocListener({
    super.key,
    required this.listeners,
    required this.child,
  });

  /// The list of listener configurations.
  final List<_BlocListenerConfig> listeners;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _buildListeners(context, 0);
  }

  Widget _buildListeners(BuildContext context, int index) {
    if (index >= listeners.length) {
      return child;
    }

    final config = listeners[index];
    return config._build(context, _buildListeners(context, index + 1));
  }
}

/// Configuration for a bloc listener.
class _BlocListenerConfig<B extends DragonflyBlocBase<dynamic, S>, S> {
  const _BlocListenerConfig({
    required this.listener,
    this.listenWhen,
  });

  final void Function(BuildContext context, S state) listener;
  final bool Function(S previous, S current)? listenWhen;

  Widget _build(BuildContext context, Widget child) {
    return _InternalBlocListener<B, S>(
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }
}

class _InternalBlocListener<B extends DragonflyBlocBase<dynamic, S>, S>
    extends StatefulWidget {
  const _InternalBlocListener({
    required this.listener,
    this.listenWhen,
    required this.child,
  });

  final void Function(BuildContext context, S state) listener;
  final bool Function(S previous, S current)? listenWhen;
  final Widget child;

  @override
  State<_InternalBlocListener<B, S>> createState() =>
      _InternalBlocListenerState<B, S>();
}

class _InternalBlocListenerState<B extends DragonflyBlocBase<dynamic, S>, S>
    extends State<_InternalBlocListener<B, S>> {
  late B _bloc;
  late S _previousState;
  StreamSubscription<S>? _subscription;

  @override
  void initState() {
    super.initState();
    _bloc = DragonflyBlocProvider.of<B>(context);
    _previousState = _bloc.state;
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc.stream.listen((state) {
      if (widget.listenWhen?.call(_previousState, state) ?? true) {
        widget.listener(context, state);
      }
      _previousState = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Helper function to create a bloc listener config.
_BlocListenerConfig<B, S> blocListener<B extends DragonflyBlocBase<dynamic, S>, S>({
  required void Function(BuildContext context, S state) listener,
  bool Function(S previous, S current)? listenWhen,
}) {
  return _BlocListenerConfig<B, S>(
    listener: listener,
    listenWhen: listenWhen,
  );
}
