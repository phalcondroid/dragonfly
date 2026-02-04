// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_feature.dart';

// **************************************************************************
// DragonflyStateManagerGenerator
// **************************************************************************

/// Generated mixin for CharacterFeature.
///
/// Provides logging configuration.
/// State pattern matching (when, maybeWhen, map) is available directly on the state.
mixin _$CharacterFeatureMixin on Feature<CharacterState> {
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
