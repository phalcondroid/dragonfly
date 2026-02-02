import 'package:flutter/material.dart';
import 'package:dragonfly/framework/feature/feature.dart';
import 'package:dragonfly/framework/feature/feature_provider.dart';
import 'package:dragonfly/framework/feature/feature_builder.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';

/// Base class for screens that use a Dragonfly Feature.
///
/// This abstract class provides automatic feature injection and
/// convenient access to feature methods.
///
/// Example:
/// ```dart
/// class CharacterScreen extends DragonflyScreen<CharacterFeature, CharacterState> {
///   const CharacterScreen({super.key});
///
///   @override
///   Widget build(BuildContext context, CharacterFeature feature, CharacterState state) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('Character'),
///         actions: [
///           IconButton(
///             icon: const Icon(Icons.refresh),
///             onPressed: feature.refresh,
///           ),
///         ],
///       ),
///       body: state.when(
///         initial: () => _InitialView(onFetch: () => feature.fetchCharacter(1)),
///         loading: () => const CircularProgressIndicator(),
///         loaded: (character) => _CharacterDetail(character: character),
///         error: (message) => _ErrorView(message: message),
///       ),
///     );
///   }
/// }
/// ```
abstract class DragonflyScreen<F extends Feature<S>, S> extends StatelessWidget {
  const DragonflyScreen({super.key});

  /// Builds the screen with access to the feature and current state.
  Widget buildScreen(BuildContext context, F feature, S state);

  @override
  Widget build(BuildContext context) {
    return FeatureBuilder<F, S>(
      builder: (context, state) {
        final feature = context.feature<F>();
        return buildScreen(context, feature, state);
      },
    );
  }
}

/// A screen wrapper that automatically provides a feature.
///
/// Use this to wrap a screen that needs a feature but doesn't extend
/// [DragonflyScreen].
///
/// Example:
/// ```dart
/// // In your routes:
/// ScreenProvider<CharacterFeature>(
///   child: const CharacterView(),
/// )
/// ```
class ScreenProvider<F extends Feature<dynamic>> extends StatelessWidget {
  const ScreenProvider({
    super.key,
    this.create,
    required this.child,
  });

  /// Optional factory to create the feature.
  /// If not provided, gets the feature from DI.
  final F Function(BuildContext context)? create;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FeatureProvider<F>(
      create: create ?? (_) => DragonflyContainer.I.get<F>(),
      child: child,
    );
  }
}

/// Extension methods for easier navigation with features.
extension FeatureNavigationExtension on BuildContext {
  /// Pushes a route and provides a feature to it.
  Future<T?> pushFeatureRoute<F extends Feature<dynamic>, T>({
    required Widget child,
    F Function(BuildContext)? create,
  }) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(
        builder: (context) => ScreenProvider<F>(
          create: create,
          child: child,
        ),
      ),
    );
  }

  /// Pushes a named route.
  Future<T?> pushFeatureNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }
}

/// A side effect handler widget that processes common side effects.
///
/// Automatically handles [NavigateTo], [ShowSnackbar], [ShowDialog], and [Pop].
///
/// Example:
/// ```dart
/// DefaultSideEffectHandler<CharacterFeature>(
///   child: const CharacterScreen(),
/// )
/// ```
class DefaultSideEffectHandler<F extends Feature<dynamic>> extends StatelessWidget {
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
  final void Function(BuildContext, FeatureSideEffect)? onUnknown;

  @override
  Widget build(BuildContext context) {
    return FeatureSideEffectListener<F>(
      listener: (context, effect) => _handleEffect(context, effect),
      child: child,
    );
  }

  void _handleEffect(BuildContext context, FeatureSideEffect effect) {
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
