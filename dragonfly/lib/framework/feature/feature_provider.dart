import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/feature/feature.dart';

/// Provides a [Feature] to its descendants.
///
/// Use [FeatureProvider.of] to access the feature from descendant widgets.
///
/// Example:
/// ```dart
/// FeatureProvider<CharacterFeature>(
///   create: (context) => CharacterFeature(),
///   child: const CharacterScreen(),
/// )
/// ```
class FeatureProvider<F extends Feature<dynamic>> extends StatefulWidget {
  /// Creates a [FeatureProvider].
  const FeatureProvider({
    super.key,
    required this.create,
    this.lazy = true,
    required this.child,
  });

  /// Factory function to create the feature.
  final F Function(BuildContext context) create;

  /// Whether to lazily create the feature.
  final bool lazy;

  /// The child widget.
  final Widget child;

  /// Gets the feature of type [F] from the widget tree.
  static F of<F extends Feature<dynamic>>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_FeatureInherited<F>>();

    if (provider == null) {
      throw FlutterError(
        'FeatureProvider.of() called with a context that does not contain a '
        'Feature of type $F.\n'
        'Make sure to wrap your widget tree with FeatureProvider<$F>.',
      );
    }

    return provider.feature;
  }

  /// Tries to get the feature of type [F] from the widget tree.
  /// Returns null if not found.
  static F? maybeOf<F extends Feature<dynamic>>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_FeatureInherited<F>>();
    return provider?.feature;
  }

  @override
  State<FeatureProvider<F>> createState() => _FeatureProviderState<F>();
}

class _FeatureProviderState<F extends Feature<dynamic>>
    extends State<FeatureProvider<F>> {
  late F _feature;
  bool _initialized = false;

  F get feature {
    if (!_initialized) {
      _feature = widget.create(context);
      _initialized = true;
    }
    return _feature;
  }

  @override
  void initState() {
    super.initState();
    if (!widget.lazy) {
      _feature = widget.create(context);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _feature.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureInherited<F>(
      feature: feature,
      child: widget.child,
    );
  }
}

class _FeatureInherited<F extends Feature<dynamic>> extends InheritedWidget {
  const _FeatureInherited({
    required this.feature,
    required super.child,
  });

  final F feature;

  @override
  bool updateShouldNotify(_FeatureInherited<F> oldWidget) => false;
}

/// Extension to easily access features from BuildContext.
extension FeatureContextExtension on BuildContext {
  /// Gets the feature of type [F] from the widget tree.
  F feature<F extends Feature<dynamic>>() => FeatureProvider.of<F>(this);

  /// Tries to get the feature of type [F] from the widget tree.
  F? maybeFeature<F extends Feature<dynamic>>() => FeatureProvider.maybeOf<F>(this);
}
