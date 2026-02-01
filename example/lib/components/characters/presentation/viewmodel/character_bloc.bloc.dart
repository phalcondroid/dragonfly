// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_bloc.dart';

// **************************************************************************
// DragonflyBlocGenerator
// **************************************************************************

/// Generated mixin for CharacterBloc.
///
/// Provides helper methods for event handling and state management.
mixin _$CharacterBlocMixin on DragonflyBloc<UserEvent, UserState> {
  /// Dispatches an event to the bloc.
  void dispatch(UserEvent event) => add(event);

  /// The current state of the bloc.
  UserState get currentState => state;

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('[CharacterBloc] Error: $error');
    super.onError(error, stackTrace);
  }
}
