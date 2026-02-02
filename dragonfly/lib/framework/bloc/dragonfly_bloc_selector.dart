import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/bloc/dragonfly_bloc.dart';
import 'package:dragonfly/framework/bloc/dragonfly_bloc_provider.dart';

/// Signature for the selector function.
typedef DragonflyBlocSelector<S, T> = T Function(S state);

/// A widget that rebuilds only when a selected part of the state changes.
///
/// This is more efficient than [DragonflyBlocBuilder] when you only care
/// about a specific part of the state.
///
/// ```dart
/// DragonflyBlocSelectorWidget<UserBloc, UserState, String?>(
///   selector: (state) => state.maybeWhen(
///     loaded: (user) => user.name,
///     orElse: () => null,
///   ),
///   builder: (context, userName) {
///     if (userName == null) return CircularProgressIndicator();
///     return Text(userName);
///   },
/// )
/// ```
class DragonflyBlocSelectorWidget<B extends DragonflyBlocBase<dynamic, S>, S, T>
    extends StatefulWidget {
  /// Creates a [DragonflyBlocSelectorWidget].
  const DragonflyBlocSelectorWidget({
    super.key,
    this.bloc,
    required this.selector,
    required this.builder,
  });

  /// The BLoC to listen to. If null, it will be obtained from the context.
  final B? bloc;

  /// The selector function that extracts a value from the state.
  final DragonflyBlocSelector<S, T> selector;

  /// The builder function called when the selected value changes.
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<DragonflyBlocSelectorWidget<B, S, T>> createState() =>
      _DragonflyBlocSelectorWidgetState<B, S, T>();
}

class _DragonflyBlocSelectorWidgetState<B extends DragonflyBlocBase<dynamic, S>, S,
    T> extends State<DragonflyBlocSelectorWidget<B, S, T>> {
  late B _bloc;
  late T _selectedValue;
  StreamSubscription<S>? _subscription;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.bloc<B>();
    _selectedValue = widget.selector(_bloc.state);
    _subscribe();
  }

  @override
  void didUpdateWidget(DragonflyBlocSelectorWidget<B, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.maybeBloc<B>();
    final currentBloc = widget.bloc ?? context.bloc<B>();
    if (oldBloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _selectedValue = widget.selector(_bloc.state);
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc.stream.listen((state) {
      final newValue = widget.selector(state);
      if (_selectedValue != newValue) {
        setState(() {
          _selectedValue = newValue;
        });
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue);
  }
}
