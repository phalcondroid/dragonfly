import 'package:flutter/material.dart';
import 'package:dragonfly/framework/feature/state_manager.dart';
import 'package:dragonfly/framework/feature/state_manager_provider.dart';
import 'package:dragonfly/framework/feature/state_manager_builder.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';

/// Base class for screens that use a Dragonfly StateManager.
///
/// This abstract class provides automatic state manager injection and
/// convenient access to state manager methods.
///
/// Example:
/// ```dart
/// class CharacterScreen extends DragonflyScreenBase<CharacterStateManager, CharacterState> {
///   const CharacterScreen({super.key});
///
///   @override
///   Widget buildScreen(BuildContext context, CharacterStateManager stateManager, CharacterState state) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('Character'),
///         actions: [
///           IconButton(
///             icon: const Icon(Icons.refresh),
///             onPressed: stateManager.refresh,
///           ),
///         ],
///       ),
///       body: state.when(
///         initial: () => _InitialView(onFetch: () => stateManager.fetchCharacter(1)),
///         loading: () => const CircularProgressIndicator(),
///         loaded: (character) => _CharacterDetail(character: character),
///         error: (message) => _ErrorView(message: message),
///       ),
///     );
///   }
/// }
/// ```
abstract class DragonflyScreenBase<SM extends StateManager<S>, S> extends StatelessWidget {
  const DragonflyScreenBase({super.key});

  /// Builds the screen with access to the state manager and current state.
  Widget buildScreen(BuildContext context, SM stateManager, S state);

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<SM, S>(
      builder: (context, state) {
        final sm = context.stateManager<SM>();
        return buildScreen(context, sm, state);
      },
    );
  }
}

/// A screen wrapper that automatically provides a state manager.
///
/// Use this to wrap a screen that needs a state manager but doesn't extend
/// [DragonflyScreenBase].
///
/// Example:
/// ```dart
/// // In your routes:
/// ScreenProvider<CharacterStateManager>(
///   child: const CharacterView(),
/// )
/// ```
class ScreenProvider<SM extends StateManager<dynamic>> extends StatelessWidget {
  const ScreenProvider({
    super.key,
    this.create,
    required this.child,
  });

  /// Optional factory to create the state manager.
  /// If not provided, gets the state manager from DI.
  final SM Function(BuildContext context)? create;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StateManagerProvider<SM>(
      create: create ?? (_) => DragonflyContainer.I.get<SM>(),
      child: child,
    );
  }
}

/// Extension methods for easier navigation with state managers.
extension StateManagerNavigationExtension on BuildContext {
  /// Pushes a route and provides a state manager to it.
  Future<T?> pushStateManagerRoute<SM extends StateManager<dynamic>, T>({
    required Widget child,
    SM Function(BuildContext)? create,
  }) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(
        builder: (context) => ScreenProvider<SM>(
          create: create,
          child: child,
        ),
      ),
    );
  }

  /// Pushes a named route.
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }
}

/// A side effect handler widget that processes common side effects.
///
/// Automatically handles [NavigateTo], [ShowSnackbar], [ShowDialog], and [Pop].
///
/// Example:
/// ```dart
/// DefaultSideEffectHandler<CharacterStateManager>(
///   child: const CharacterScreen(),
/// )
/// ```
class DefaultSideEffectHandler<SM extends StateManager<dynamic>> extends StatelessWidget {
  const DefaultSideEffectHandler({
    super.key,
    required this.child,
    this.onNavigate,
    this.onSnackbar,
    this.onDialog,
    this.onPop,
    this.onUnknown,
  });

  final Widget child;
  final void Function(BuildContext, NavigateTo)? onNavigate;
  final void Function(BuildContext, ShowSnackbar)? onSnackbar;
  final void Function(BuildContext, ShowDialog)? onDialog;
  final void Function(BuildContext, Pop)? onPop;
  final void Function(BuildContext, StateManagerSideEffect)? onUnknown;

  @override
  Widget build(BuildContext context) {
    return StateManagerSideEffectListener<SM>(
      listener: (context, effect) => _handleEffect(context, effect),
      child: child,
    );
  }

  void _handleEffect(BuildContext context, StateManagerSideEffect effect) {
    switch (effect) {
      case NavigateTo():
        if (onNavigate != null) {
          onNavigate!(context, effect);
        } else {
          _defaultNavigate(context, effect);
        }
      case ShowSnackbar():
        if (onSnackbar != null) {
          onSnackbar!(context, effect);
        } else {
          _defaultSnackbar(context, effect);
        }
      case ShowDialog():
        if (onDialog != null) {
          onDialog!(context, effect);
        } else {
          _defaultDialog(context, effect);
        }
      case Pop():
        if (onPop != null) {
          onPop!(context, effect);
        } else {
          _defaultPop(context, effect);
        }
      default:
        onUnknown?.call(context, effect);
    }
  }

  void _defaultNavigate(BuildContext context, NavigateTo effect) {
    if (effect.replace) {
      Navigator.of(context).pushReplacementNamed(
        effect.route,
        arguments: effect.arguments,
      );
    } else {
      Navigator.of(context).pushNamed(
        effect.route,
        arguments: effect.arguments,
      );
    }
  }

  void _defaultSnackbar(BuildContext context, ShowSnackbar effect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(effect.message),
        duration: effect.duration,
      ),
    );
  }

  void _defaultDialog(BuildContext context, ShowDialog effect) {
    showDialog(
      context: context,
      builder: effect.builder,
    );
  }

  void _defaultPop(BuildContext context, Pop effect) {
    Navigator.of(context).pop(effect.result);
  }
}

// Backwards compatibility aliases
@Deprecated('Use StateManagerNavigationExtension instead')
extension FeatureNavigationExtension on BuildContext {
  @Deprecated('Use pushStateManagerRoute instead')
  Future<T?> pushFeatureRoute<F extends StateManager<dynamic>, T>({
    required Widget child,
    F Function(BuildContext)? create,
  }) {
    return pushStateManagerRoute<F, T>(child: child, create: create);
  }

  @Deprecated('Use pushNamed instead')
  Future<T?> pushFeatureNamed<T>(String routeName, {Object? arguments}) {
    return pushNamed<T>(routeName, arguments: arguments);
  }
}
