// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_view.dart';

// **************************************************************************
// DragonflyViewGenerator
// **************************************************************************

/// Generated mixin for CharacterView.
///
/// Provides state-aware widget builders and bloc helpers.
mixin _$CharacterViewMixin on StatelessWidget {
  /// Gets the bloc from the context.
  CharacterBloc getBloc(BuildContext context) {
    return DragonflyBlocProvider.of<CharacterBloc>(context);
  }

  /// Dispatches an event to the bloc.
  void dispatch(BuildContext context, CharacterEvent event) {
    getBloc(context).add(event);
  }

  /// Builds a widget based on the current state.
  ///
  /// Each callback corresponds to a state variant.
  Widget buildStateWidget(
    BuildContext context, {
    required Widget Function() onInitial,
    required Widget Function() onLoading,
    required Widget Function(Character character) onLoaded,
    required Widget Function(List<Character> characters) onCharacterList,
    required Widget Function(String message) onError,
  }) {
    return DragonflyBlocBuilder<CharacterBloc, CharacterState>(
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

  /// Wraps a child widget with a state listener.
  ///
  /// The listener is called whenever the state changes.
  Widget withStateListener(
    BuildContext context, {
    required Widget child,
    required void Function(BuildContext, CharacterState) listener,
    bool Function(CharacterState, CharacterState)? listenWhen,
  }) {
    return DragonflyBlocListener<CharacterBloc, CharacterState>(
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }
}

/// Wrapper widget that provides [CharacterBloc] to [CharacterView].
///
/// Use this instead of manually wrapping with DragonflyBlocProvider.
/// ```dart
/// // Instead of:
/// DragonflyBlocProvider<CharacterBloc>(
///   create: (context) => DragonflyContainer.I.get<CharacterBloc>(),
///   child: const CharacterView(),
/// )
///
/// // Use:
/// const CharacterViewProvider()
/// ```
class CharacterViewProvider extends StatelessWidget {
  const CharacterViewProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return DragonflyBlocProvider<CharacterBloc>(
      create: (context) => DragonflyContainer.I.get<CharacterBloc>(),
      child: const CharacterView(),
    );
  }
}

/// A standalone widget that builds based on [CharacterState] variants.
class CharacterStateBuilderWidget extends StatelessWidget {
  const CharacterStateBuilderWidget({
    super.key,
    required this.state,
    required this.onInitial,
    required this.onLoading,
    required this.onLoaded,
    required this.onCharacterList,
    required this.onError,
  });

  final CharacterState state;
  final Widget Function() onInitial;
  final Widget Function() onLoading;
  final Widget Function(Character character) onLoaded;
  final Widget Function(List<Character> characters) onCharacterList;
  final Widget Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    return state.when(
      initial: onInitial,
      loading: onLoading,
      loaded: (character) => onLoaded(character),
      characterList: (characters) => onCharacterList(characters),
      error: (message) => onError(message),
    );
  }
}
