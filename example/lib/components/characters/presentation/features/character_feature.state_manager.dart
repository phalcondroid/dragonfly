// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_feature.dart';

// **************************************************************************
// DragonflyStateManagerGenerator
// **************************************************************************

/// Generated mixin for CharacterFeature.
///
/// Provides logging configuration.
/// State pattern matching (when, maybeWhen, map) is available directly on the state.
mixin _$CharacterFeatureMixin on StateManager<CharacterState> {
  @override
  bool get loggingEnabled => true;
}

/// Provider widget that injects [CharacterFeature] into the widget tree.
///
/// Usage:
/// ```dart
/// CharacterFeatureProvider(
///   child: const MyWidget(),
/// )
/// ```
class CharacterFeatureProvider extends StatelessWidget {
  const CharacterFeatureProvider({
    super.key,
    this.create,
    required this.child,
  });

  /// Optional factory to create the state manager.
  /// If not provided, gets the state manager from DI.
  final CharacterFeature Function(BuildContext context)? create;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StateManagerProvider<CharacterFeature>(
      create: create ?? (_) => DragonflyContainer.I.get<CharacterFeature>(),
      child: child,
    );
  }
}

/// Builder widget that only builds when state is [CharacterStateInitial].
///
/// Usage:
/// ```dart
/// CharacterInitial(
///   builder: () => const MyWidget(),
/// )
/// ```
class CharacterInitial extends StatelessWidget {
  const CharacterInitial({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
  });

  /// Builder function called with state parameters when state is [CharacterStateInitial].
  final Widget Function() builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(CharacterState previous, CharacterState current)?
      buildWhen;

  /// Optional widget to show when state is not [CharacterStateInitial].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<CharacterFeature, CharacterState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is CharacterStateInitial) {
          return builder();
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder widget that only builds when state is [CharacterStateLoading].
///
/// Usage:
/// ```dart
/// CharacterLoading(
///   builder: () => const MyWidget(),
/// )
/// ```
class CharacterLoading extends StatelessWidget {
  const CharacterLoading({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
  });

  /// Builder function called with state parameters when state is [CharacterStateLoading].
  final Widget Function() builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(CharacterState previous, CharacterState current)?
      buildWhen;

  /// Optional widget to show when state is not [CharacterStateLoading].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<CharacterFeature, CharacterState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is CharacterStateLoading) {
          return builder();
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder widget that only builds when state is [CharacterStateLoaded].
///
/// Usage:
/// ```dart
/// CharacterLoaded(
///   builder: (character) => MyWidget(character),
/// )
/// ```
class CharacterLoaded extends StatelessWidget {
  const CharacterLoaded({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
    this.initialCharacter,
  });

  /// Builder function called with state parameters when state is [CharacterStateLoaded].
  final Widget Function(Character character) builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(CharacterState previous, CharacterState current)?
      buildWhen;

  /// Optional widget to show when state is not [CharacterStateLoaded].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  /// Initial value for character before state loads.
  final Character? initialCharacter;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<CharacterFeature, CharacterState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is CharacterStateLoaded) {
          return builder(state.character);
        }
        // Check if initial data is provided
        if (initialCharacter != null) {
          return builder(initialCharacter!);
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder widget that only builds when state is [CharacterStateCharacterList].
///
/// Usage:
/// ```dart
/// CharacterCharacterList(
///   builder: (characters) => MyWidget(characters),
/// )
/// ```
class CharacterCharacterList extends StatelessWidget {
  const CharacterCharacterList({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
    this.initialCharacters,
  });

  /// Builder function called with state parameters when state is [CharacterStateCharacterList].
  final Widget Function(List<Character> characters) builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(CharacterState previous, CharacterState current)?
      buildWhen;

  /// Optional widget to show when state is not [CharacterStateCharacterList].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  /// Initial value for characters before state loads.
  final List<Character>? initialCharacters;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<CharacterFeature, CharacterState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is CharacterStateCharacterList) {
          return builder(state.characters);
        }
        // Check if initial data is provided
        if (initialCharacters != null) {
          return builder(initialCharacters!);
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder widget that only builds when state is [CharacterStateError].
///
/// Usage:
/// ```dart
/// CharacterError(
///   builder: (message) => MyWidget(message),
/// )
/// ```
class CharacterError extends StatelessWidget {
  const CharacterError({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
    this.initialMessage,
  });

  /// Builder function called with state parameters when state is [CharacterStateError].
  final Widget Function(String message) builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(CharacterState previous, CharacterState current)?
      buildWhen;

  /// Optional widget to show when state is not [CharacterStateError].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  /// Initial value for message before state loads.
  final String? initialMessage;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<CharacterFeature, CharacterState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is CharacterStateError) {
          return builder(state.message);
        }
        // Check if initial data is provided
        if (initialMessage != null) {
          return builder(initialMessage!);
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Extension methods for using CharacterFeature in widgets.
extension CharacterFeatureBuildContextExtension on BuildContext {
  /// Gets the [CharacterFeature] from the widget tree.
  CharacterFeature get characterFeature => stateManager<CharacterFeature>();

  /// Builds a widget based on the current state of [CharacterFeature].
  /// Consider using individual state builders like [CharacterLoaded] instead.
  Widget characterFeatureBuilder({
    required Widget Function() onInitial,
    required Widget Function() onLoading,
    required Widget Function(Character character) onLoaded,
    required Widget Function(List<Character> characters) onCharacterList,
    required Widget Function(String message) onError,
  }) {
    return StateManagerBuilder<CharacterFeature, CharacterState>(
      builder: (context, state) {
        return state.when(
          initial: onInitial,
          loading: onLoading,
          loaded: (character) => onLoaded(character),
          characterList: (characters) => onCharacterList(characters),
          error: (message) => onError(message),
        );
      },
    );
  }
}
