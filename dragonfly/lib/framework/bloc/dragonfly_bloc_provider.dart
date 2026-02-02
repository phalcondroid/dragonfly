import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/bloc/dragonfly_bloc.dart';

/// A widget that provides a [DragonflyBlocBase] to its descendants.
///
/// Usage:
/// ```dart
/// DragonflyBlocProvider<UserBloc>(
///   create: (context) => UserBloc(),
///   child: MyApp(),
/// )
/// ```
class DragonflyBlocProvider<T extends DragonflyBlocBase<dynamic, dynamic>>
    extends StatefulWidget {
  /// Creates a [DragonflyBlocProvider].
  const DragonflyBlocProvider({
    super.key,
    required this.create,
    required this.child,
    this.lazy = true,
  });

  /// Factory function to create the BLoC.
  final T Function(BuildContext context) create;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether to lazily create the BLoC.
  ///
  /// If true (default), the BLoC is created when first accessed.
  /// If false, the BLoC is created immediately.
  final bool lazy;

  /// Gets the BLoC of type [T] from the nearest ancestor [DragonflyBlocProvider].
  ///
  /// Throws if no provider is found.
  static T of<T extends DragonflyBlocBase<dynamic, dynamic>>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_DragonflyBlocInherited<T>>();
    if (provider == null) {
      throw FlutterError(
        'DragonflyBlocProvider.of() called with a context that does not '
        'contain a DragonflyBlocProvider<$T>.\n'
        'Make sure to wrap your widget tree with DragonflyBlocProvider<$T>.',
      );
    }
    return provider.bloc;
  }

  /// Gets the BLoC of type [T] from the nearest ancestor [DragonflyBlocProvider],
  /// or null if not found.
  static T? maybeOf<T extends DragonflyBlocBase<dynamic, dynamic>>(
    BuildContext context,
  ) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_DragonflyBlocInherited<T>>();
    return provider?.bloc;
  }

  @override
  State<DragonflyBlocProvider<T>> createState() =>
      _DragonflyBlocProviderState<T>();
}

class _DragonflyBlocProviderState<T extends DragonflyBlocBase<dynamic, dynamic>>
    extends State<DragonflyBlocProvider<T>> {
  T? _bloc;

  T get bloc {
    _bloc ??= widget.create(context);
    return _bloc!;
  }

  @override
  void initState() {
    super.initState();
    if (!widget.lazy) {
      _bloc = widget.create(context);
    }
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DragonflyBlocInherited<T>(
      bloc: bloc,
      child: widget.child,
    );
  }
}

class _DragonflyBlocInherited<T extends DragonflyBlocBase<dynamic, dynamic>>
    extends InheritedWidget {
  const _DragonflyBlocInherited({
    required this.bloc,
    required super.child,
  });

  final T bloc;

  @override
  bool updateShouldNotify(_DragonflyBlocInherited<T> oldWidget) {
    return bloc != oldWidget.bloc;
  }
}

/// Extension for easy BLoC access from BuildContext.
extension DragonflyBlocContextExtension on BuildContext {
  /// Gets the BLoC of type [T] from the widget tree.
  T bloc<T extends DragonflyBlocBase<dynamic, dynamic>>() {
    return DragonflyBlocProvider.of<T>(this);
  }

  /// Gets the BLoC of type [T] from the widget tree, or null if not found.
  T? maybeBloc<T extends DragonflyBlocBase<dynamic, dynamic>>() {
    return DragonflyBlocProvider.maybeOf<T>(this);
  }
}
