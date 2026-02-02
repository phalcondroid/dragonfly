import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dragonfly/framework/feature/feature.dart';
import 'package:dragonfly/framework/feature/feature_provider.dart';

/// A widget that rebuilds when the feature's state changes.
///
/// Example:
/// ```dart
/// FeatureBuilder<CharacterFeature, CharacterState>(
///   builder: (context, state) {
///     return state.when(
///       initial: () => const Text('Tap to load'),
///       loading: () => const CircularProgressIndicator(),
///       loaded: (character) => Text(character.name),
///       error: (message) => Text(message),
///     );
///   },
/// )
/// ```
class FeatureBuilder<F extends Feature<S>, S> extends StatefulWidget {
  const FeatureBuilder({
    super.key,
    this.feature,
    required this.builder,
    this.buildWhen,
  });

  /// The feature to listen to. If null, uses the feature from context.
  final F? feature;

  /// The builder function called when state changes.
  final FeatureWidgetBuilder<S> builder;

  /// Optional function to determine if the builder should be called.
  final FeatureStateComparator<S>? buildWhen;

  @override
  State<FeatureBuilder<F, S>> createState() => _FeatureBuilderState<F, S>();
}

class _FeatureBuilderState<F extends Feature<S>, S>
    extends State<FeatureBuilder<F, S>> {
  late F _feature;
  late S _state;
  StreamSubscription<S>? _subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feature = widget.feature ?? context.feature<F>();
    _state = _feature.state;
    _subscribe();
  }

  @override
  void didUpdateWidget(FeatureBuilder<F, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newFeature = widget.feature ?? context.feature<F>();
    if (newFeature != _feature) {
      _unsubscribe();
      _feature = newFeature;
      _state = _feature.state;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _feature.stream.listen((state) {
      if (widget.buildWhen?.call(_state, state) ?? true) {
        setState(() => _state = state);
      } else {
        _state = state;
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _state);
  }
}

/// A widget that listens to feature state changes and calls a listener.
///
/// Unlike [FeatureBuilder], this doesn't rebuild - it's for side effects.
///
/// Example:
/// ```dart
/// FeatureListener<CharacterFeature, CharacterState>(
///   listener: (context, state) {
///     if (state is CharacterStateError) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(state.message)),
///       );
///     }
///   },
///   child: const CharacterView(),
/// )
/// ```
class FeatureListener<F extends Feature<S>, S> extends StatefulWidget {
  const FeatureListener({
    super.key,
    this.feature,
    required this.listener,
    this.listenWhen,
    required this.child,
  });

  /// The feature to listen to. If null, uses the feature from context.
  final F? feature;

  /// The listener called when state changes.
  final void Function(BuildContext context, S state) listener;

  /// Optional function to determine if the listener should be called.
  final FeatureStateComparator<S>? listenWhen;

  /// The child widget.
  final Widget child;

  @override
  State<FeatureListener<F, S>> createState() => _FeatureListenerState<F, S>();
}

class _FeatureListenerState<F extends Feature<S>, S>
    extends State<FeatureListener<F, S>> {
  late F _feature;
  late S _previousState;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feature = widget.feature ?? context.feature<F>();
    _previousState = _feature.state;
    _subscribe();
  }

  @override
  void didUpdateWidget(FeatureListener<F, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newFeature = widget.feature ?? context.feature<F>();
    if (newFeature != _feature) {
      _unsubscribe();
      _feature = newFeature;
      _previousState = _feature.state;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _feature.stream.listen((state) {
      if (widget.listenWhen?.call(_previousState, state) ?? true) {
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
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A widget that listens to feature side effects.
///
/// Example:
/// ```dart
/// FeatureSideEffectListener<CharacterFeature>(
///   listener: (context, effect) {
///     if (effect is NavigateTo) {
///       Navigator.pushNamed(context, effect.route);
///     } else if (effect is ShowSnackbar) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(effect.message)),
///       );
///     }
///   },
///   child: const CharacterView(),
/// )
/// ```
class FeatureSideEffectListener<F extends Feature<dynamic>>
    extends StatefulWidget {
  const FeatureSideEffectListener({
    super.key,
    this.feature,
    required this.listener,
    required this.child,
  });

  /// The feature to listen to. If null, uses the feature from context.
  final F? feature;

  /// The listener called when a side effect is emitted.
  final void Function(BuildContext context, FeatureSideEffect effect) listener;

  /// The child widget.
  final Widget child;

  @override
  State<FeatureSideEffectListener<F>> createState() =>
      _FeatureSideEffectListenerState<F>();
}

class _FeatureSideEffectListenerState<F extends Feature<dynamic>>
    extends State<FeatureSideEffectListener<F>> {
  late F _feature;
  StreamSubscription<FeatureSideEffect>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feature = widget.feature ?? context.feature<F>();
    _subscribe();
  }

  @override
  void didUpdateWidget(FeatureSideEffectListener<F> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newFeature = widget.feature ?? context.feature<F>();
    if (newFeature != _feature) {
      _unsubscribe();
      _feature = newFeature;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _feature.sideEffects.listen((effect) {
      widget.listener(context, effect);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Combines [FeatureBuilder] and [FeatureListener] into one widget.
class FeatureConsumer<F extends Feature<S>, S> extends StatelessWidget {
  const FeatureConsumer({
    super.key,
    this.feature,
    required this.builder,
    required this.listener,
    this.buildWhen,
    this.listenWhen,
  });

  final F? feature;
  final FeatureWidgetBuilder<S> builder;
  final void Function(BuildContext context, S state) listener;
  final FeatureStateComparator<S>? buildWhen;
  final FeatureStateComparator<S>? listenWhen;

  @override
  Widget build(BuildContext context) {
    return FeatureListener<F, S>(
      feature: feature,
      listener: listener,
      listenWhen: listenWhen,
      child: FeatureBuilder<F, S>(
        feature: feature,
        builder: builder,
        buildWhen: buildWhen,
      ),
    );
  }
}

/// Selects a specific part of the state and only rebuilds when it changes.
class FeatureSelector<F extends Feature<S>, S, T> extends StatefulWidget {
  const FeatureSelector({
    super.key,
    this.feature,
    required this.selector,
    required this.builder,
  });

  final F? feature;
  final T Function(S state) selector;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<FeatureSelector<F, S, T>> createState() =>
      _FeatureSelectorState<F, S, T>();
}

class _FeatureSelectorState<F extends Feature<S>, S, T>
    extends State<FeatureSelector<F, S, T>> {
  late F _feature;
  late T _selectedValue;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feature = widget.feature ?? context.feature<F>();
    _selectedValue = widget.selector(_feature.state);
    _subscribe();
  }

  @override
  void didUpdateWidget(FeatureSelector<F, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newFeature = widget.feature ?? context.feature<F>();
    if (newFeature != _feature) {
      _unsubscribe();
      _feature = newFeature;
      _selectedValue = widget.selector(_feature.state);
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _feature.stream.listen((state) {
      final newValue = widget.selector(state);
      if (newValue != _selectedValue) {
        setState(() => _selectedValue = newValue);
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue);
  }
}
