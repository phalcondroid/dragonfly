// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_feature.dart';

// **************************************************************************
// DragonflyFeatureGenerator
// **************************************************************************

/// Generated mixin for CharacterFeature.
///
/// Provides helper methods and state handling utilities.
mixin _$CharacterFeatureMixin on Feature<CharacterState> {
  @override
  bool get loggingEnabled => true;

  /// Pattern matches on the current state and returns a value.
  ///
  /// All callbacks are required for exhaustive matching.
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(Character character) loaded,
    required T Function(List<Character> characters) characterList,
    required T Function(String message) error,
  }) {
    final s = state;
    if (s is CharacterStateInitial) {
      return initial();
    } else if (s is CharacterStateLoading) {
      return loading();
    } else if (s is CharacterStateLoaded) {
      return loaded(s.character);
    } else if (s is CharacterStateCharacterList) {
      return characterList(s.characters);
    } else if (s is CharacterStateError) {
      return error(s.message);
    }
    throw StateError('Unknown state type: $s');
  }

  /// Pattern matches on the current state with optional callbacks.
  ///
  /// Returns orElse if no callback matches.
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(Character character)? loaded,
    T Function(List<Character> characters)? characterList,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    final s = state;
    if (s is CharacterStateInitial && initial != null) {
      return initial();
    } else if (s is CharacterStateLoading && loading != null) {
      return loading();
    } else if (s is CharacterStateLoaded && loaded != null) {
      return loaded(s.character);
    } else if (s is CharacterStateCharacterList && characterList != null) {
      return characterList(s.characters);
    } else if (s is CharacterStateError && error != null) {
      return error(s.message);
    }
    return orElse();
  }

  /// Maps the current state to a value using typed callbacks.
  T map<T>({
    required T Function(CharacterStateInitial state) initial,
    required T Function(CharacterStateLoading state) loading,
    required T Function(CharacterStateLoaded state) loaded,
    required T Function(CharacterStateCharacterList state) characterList,
    required T Function(CharacterStateError state) error,
  }) {
    final s = state;
    if (s is CharacterStateInitial) {
      return initial(s);
    } else if (s is CharacterStateLoading) {
      return loading(s);
    } else if (s is CharacterStateLoaded) {
      return loaded(s);
    } else if (s is CharacterStateCharacterList) {
      return characterList(s);
    } else if (s is CharacterStateError) {
      return error(s);
    }
    throw StateError('Unknown state type: $s');
  }
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

  /// Optional factory to create the feature.
  /// If not provided, gets the feature from DI.
  final CharacterFeature Function(BuildContext context)? create;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FeatureProvider<CharacterFeature>(
      create: create ?? (_) => DragonflyContainer.I.get<CharacterFeature>(),
      child: child,
    );
  }
}

/// Extension methods for using CharacterFeature in widgets.
extension CharacterFeatureBuildContextExtension on BuildContext {
  /// Gets the [CharacterFeature] from the widget tree.
  CharacterFeature get characterFeature => feature<CharacterFeature>();

  /// Builds a widget based on the current state of [CharacterFeature].
  Widget characterFeatureBuilder({
    required Widget Function() onInitial,
    required Widget Function() onLoading,
    required Widget Function(Character character) onLoaded,
    required Widget Function(List<Character> characters) onCharacterList,
    required Widget Function(String message) onError,
  }) {
    return FeatureBuilder<CharacterFeature, CharacterState>(
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
