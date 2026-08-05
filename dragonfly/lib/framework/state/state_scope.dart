import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dragonfly/framework/di/dragonfly_container.dart';
import 'package:dragonfly/framework/feature/state_manager.dart';
import 'package:dragonfly/framework/feature/state_manager_provider.dart';

/// Binds a [StateManager] to a subtree in one widget.
///
/// This replaces the three-widget stack the framework previously required —
/// a `StateManagerProvider`, a `DefaultSideEffectHandler`, and a
/// `StateManagerBuilder` — with a single wrapper. It:
///
/// * resolves the manager from the DI container (or from [create]),
/// * provides it to descendants, so `context.stateManager<SM>()` works,
/// * subscribes to its side effects and applies the default handling for
///   [NavigateTo], [ShowSnackbar], [ShowDialog] and [Pop],
/// * disposes it with the subtree.
///
/// ```dart
/// StateScope<CharacterFeature>(
///   child: const CharacterScreen(),
/// )
/// ```
///
/// Override individual effects when a screen needs different behaviour, and
/// use [onEffect] to handle side effects the framework does not know about:
///
/// ```dart
/// StateScope<CheckoutFeature>(
///   onSnackbar: (context, effect) => myBanner(context, effect.message),
///   onEffect: (context, effect) {
///     if (effect is LaunchPaymentSheet) openSheet(context, effect.token);
///   },
///   child: const CheckoutScreen(),
/// )
/// ```
class StateScope<SM extends StateManager<dynamic>> extends StatelessWidget {
  const StateScope({
    super.key,
    required this.child,
    this.create,
    this.handleSideEffects = true,
    this.onNavigate,
    this.onSnackbar,
    this.onDialog,
    this.onPop,
    this.onEffect,
  });

  /// The subtree that can read this state manager.
  final Widget child;

  /// Builds the manager. Defaults to resolving `SM` from [DragonflyContainer].
  final SM Function(BuildContext context)? create;

  /// Whether to subscribe to the manager's side-effect stream at all.
  ///
  /// Set to `false` for a nested scope that should not react to effects, so the
  /// nearest enclosing scope handles them alone and they are not applied twice.
  final bool handleSideEffects;

  final void Function(BuildContext context, NavigateTo effect)? onNavigate;
  final void Function(BuildContext context, ShowSnackbar effect)? onSnackbar;
  final void Function(BuildContext context, ShowDialog effect)? onDialog;
  final void Function(BuildContext context, Pop effect)? onPop;

  /// Called for any effect not covered by the four built-in kinds.
  final void Function(BuildContext context, StateManagerSideEffect effect)?
      onEffect;

  @override
  Widget build(BuildContext context) {
    return StateManagerProvider<SM>(
      create: create ?? (_) => DragonflyContainer.I.get<SM>(),
      lazy: false,
      child: handleSideEffects
          ? _SideEffectBinding<SM>(
              onNavigate: onNavigate,
              onSnackbar: onSnackbar,
              onDialog: onDialog,
              onPop: onPop,
              onEffect: onEffect,
              child: child,
            )
          : child,
    );
  }
}

class _SideEffectBinding<SM extends StateManager<dynamic>>
    extends StatefulWidget {
  const _SideEffectBinding({
    super.key,
    required this.child,
    this.onNavigate,
    this.onSnackbar,
    this.onDialog,
    this.onPop,
    this.onEffect,
  });

  final Widget child;
  final void Function(BuildContext context, NavigateTo effect)? onNavigate;
  final void Function(BuildContext context, ShowSnackbar effect)? onSnackbar;
  final void Function(BuildContext context, ShowDialog effect)? onDialog;
  final void Function(BuildContext context, Pop effect)? onPop;
  final void Function(BuildContext context, StateManagerSideEffect effect)?
      onEffect;

  @override
  State<_SideEffectBinding<SM>> createState() => _SideEffectBindingState<SM>();
}

class _SideEffectBindingState<SM extends StateManager<dynamic>>
    extends State<_SideEffectBinding<SM>> {
  StreamSubscription<StateManagerSideEffect>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??=
        StateManagerProvider.of<SM>(context).sideEffects.listen(_handle);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handle(StateManagerSideEffect effect) {
    // The manager can emit from an async gap after the subtree is gone.
    if (!mounted) return;

    switch (effect) {
      case NavigateTo():
        (widget.onNavigate ?? _navigate)(context, effect);
      case ShowSnackbar():
        (widget.onSnackbar ?? _snackbar)(context, effect);
      case ShowDialog():
        (widget.onDialog ?? _dialog)(context, effect);
      case Pop():
        (widget.onPop ?? _pop)(context, effect);
      default:
        widget.onEffect?.call(context, effect);
    }
  }

  void _navigate(BuildContext context, NavigateTo effect) {
    final navigator = Navigator.of(context);
    if (effect.replace) {
      navigator.pushReplacementNamed(effect.route, arguments: effect.arguments);
    } else {
      navigator.pushNamed(effect.route, arguments: effect.arguments);
    }
  }

  void _snackbar(BuildContext context, ShowSnackbar effect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(effect.message), duration: effect.duration),
    );
  }

  void _dialog(BuildContext context, ShowDialog effect) {
    showDialog<void>(context: context, builder: effect.builder);
  }

  void _pop(BuildContext context, Pop effect) {
    Navigator.of(context).pop(effect.result);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
