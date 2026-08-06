import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:dragonfly/framework/state/state_controller.dart';

/// Rebuilds whenever [controller] emits a new state.
///
/// This is the widget every generated view-mixin builder (`when`,
/// `build<Event>`, `buildFor`) returns; it can also be used directly:
///
/// ```dart
/// DragonflyStateBuilder<UserStateManagerState>(
///   controller: DragonflyContainer.I.get<$UserStateManagerController>(),
///   builder: (context, state) => state.maybeWhen(
///     loading: () => const Spinner(),
///     orElse: () => const SizedBox.shrink(),
///   ),
/// )
/// ```
///
/// The current state is read synchronously from the controller on creation, so
/// the first frame builds with the real state rather than waiting for the
/// stream. [buildWhen] can drop rebuilds by comparing previous and next state.
class DragonflyStateBuilder<S> extends StatefulWidget {
  const DragonflyStateBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.buildWhen,
  });

  /// The controller to listen to.
  final DragonflyController<S> controller;

  /// Builds with the latest state.
  final Widget Function(BuildContext context, S state) builder;

  /// Return `false` to keep the previous frame instead of rebuilding.
  final bool Function(S previous, S current)? buildWhen;

  @override
  State<DragonflyStateBuilder<S>> createState() =>
      _DragonflyStateBuilderState<S>();
}

class _DragonflyStateBuilderState<S> extends State<DragonflyStateBuilder<S>> {
  late S _state;
  StreamSubscription<S>? _subscription;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.state;
    _listen();
  }

  @override
  void didUpdateWidget(DragonflyStateBuilder<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _subscription?.cancel();
      _state = widget.controller.state;
      _listen();
    }
  }

  void _listen() {
    _subscription = widget.controller.stream.listen((next) {
      if (!mounted) return;
      final shouldBuild = widget.buildWhen?.call(_state, next) ?? true;
      if (!shouldBuild) {
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
