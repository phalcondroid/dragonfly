import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/feature/state_manager.dart';

/// Provides a [StateManager] to its descendants.
///
/// Use [StateManagerProvider.of] to access the state manager from descendant widgets.
///
/// Example:
/// ```dart
/// StateManagerProvider<CharacterStateManager>(
///   create: (context) => CharacterStateManager(),
///   child: const CharacterScreen(),
/// )
/// ```
class StateManagerProvider<SM extends StateManager<dynamic>> extends StatefulWidget {
  /// Creates a [StateManagerProvider].
  const StateManagerProvider({
    super.key,
    required this.create,
    this.lazy = true,
    required this.child,
  });

  /// Factory function to create the state manager.
  final SM Function(BuildContext context) create;

  /// Whether to lazily create the state manager.
  final bool lazy;

  /// The child widget.
  final Widget child;

  /// Gets the state manager of type [SM] from the widget tree.
  static SM of<SM extends StateManager<dynamic>>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_StateManagerInherited<SM>>();

    if (provider == null) {
      throw FlutterError(
        'StateManagerProvider.of() called with a context that does not contain a '
        'StateManager of type $SM.\n'
        'Make sure to wrap your widget tree with StateManagerProvider<$SM>.',
      );
    }

    return provider.stateManager;
  }

  /// Tries to get the state manager of type [SM] from the widget tree.
  /// Returns null if not found.
  static SM? maybeOf<SM extends StateManager<dynamic>>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_StateManagerInherited<SM>>();
    return provider?.stateManager;
  }

  @override
  State<StateManagerProvider<SM>> createState() => _StateManagerProviderState<SM>();
}

class _StateManagerProviderState<SM extends StateManager<dynamic>>
    extends State<StateManagerProvider<SM>> {
  late SM _stateManager;
  bool _initialized = false;

  SM get stateManager {
    if (!_initialized) {
      _stateManager = widget.create(context);
      _initialized = true;
    }
    return _stateManager;
  }

  @override
  void initState() {
    super.initState();
    if (!widget.lazy) {
      _stateManager = widget.create(context);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _stateManager.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StateManagerInherited<SM>(
      stateManager: stateManager,
      child: widget.child,
    );
  }
}

class _StateManagerInherited<SM extends StateManager<dynamic>> extends InheritedWidget {
  const _StateManagerInherited({
    required this.stateManager,
    required super.child,
  });

  final SM stateManager;

  @override
  bool updateShouldNotify(_StateManagerInherited<SM> oldWidget) => false;
}

/// Extension to easily access state managers from BuildContext.
extension StateManagerContextExtension on BuildContext {
  /// Gets the state manager of type [SM] from the widget tree.
  SM stateManager<SM extends StateManager<dynamic>>() => StateManagerProvider.of<SM>(this);

  /// Tries to get the state manager of type [SM] from the widget tree.
  SM? maybeStateManager<SM extends StateManager<dynamic>>() => StateManagerProvider.maybeOf<SM>(this);
}

// Backwards compatibility aliases
@Deprecated('Use StateManagerProvider instead')
typedef FeatureProvider<F extends StateManager<dynamic>> = StateManagerProvider<F>;

@Deprecated('Use StateManagerContextExtension instead')
extension FeatureContextExtension on BuildContext {
  @Deprecated('Use stateManager<SM>() instead')
  SM feature<SM extends StateManager<dynamic>>() => StateManagerProvider.of<SM>(this);

  @Deprecated('Use maybeStateManager<SM>() instead')
  SM? maybeFeature<SM extends StateManager<dynamic>>() => StateManagerProvider.maybeOf<SM>(this);
}
