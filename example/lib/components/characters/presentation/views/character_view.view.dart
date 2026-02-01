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
  void dispatch(BuildContext context, UserEvent event) {
    getBloc(context).add(event);
  }

  /// Builds a widget based on the current state.
  ///
  /// Each callback corresponds to a state variant.
  Widget buildStateWidget(
    BuildContext context, {
    required Widget Function() onInitial,
    required Widget Function() onLoading,
    required Widget Function(Character user) onLoaded,
    required Widget Function(List<Character> users) onUserList,
    required Widget Function(String message) onError,
  }) {
    return DragonflyBlocBuilder<CharacterBloc, UserState>(
      builder: (context, state) {
        return state.when(
          initial: onInitial,
          loading: onLoading,
          loaded: (user) => onLoaded(user),
          userList: (users) => onUserList(users),
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
    required void Function(BuildContext, UserState) listener,
    bool Function(UserState, UserState)? listenWhen,
  }) {
    return DragonflyBlocListener<CharacterBloc, UserState>(
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }
}

/// A standalone widget that builds based on [UserState] variants.
class UserStateBuilderWidget extends StatelessWidget {
  const UserStateBuilderWidget({
    super.key,
    required this.state,
    required this.onInitial,
    required this.onLoading,
    required this.onLoaded,
    required this.onUserList,
    required this.onError,
  });

  final UserState state;
  final Widget Function() onInitial;
  final Widget Function() onLoading;
  final Widget Function(Character user) onLoaded;
  final Widget Function(List<Character> users) onUserList;
  final Widget Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    return state.when(
      initial: onInitial,
      loading: onLoading,
      loaded: (user) => onLoaded(user),
      userList: (users) => onUserList(users),
      error: (message) => onError(message),
    );
  }
}
