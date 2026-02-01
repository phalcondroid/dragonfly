import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';

part 'user_state.state.dart';

/// Example state model for BLoC pattern.
///
/// Usage:
/// ```dart
/// // Create states
/// final initialState = UserState.initial();
/// final loadingState = UserState.loading();
/// final loadedState = UserState.loaded(user: someUser);
/// final errorState = UserState.error(message: 'Something went wrong');
///
/// // Pattern matching with when
/// state.when(
///   initial: () => Text('Welcome'),
///   loading: () => CircularProgressIndicator(),
///   loaded: (user) => Text('Hello ${user.name}'),
///   error: (message) => Text('Error: $message'),
/// );
///
/// // Use copyWith on states with data
/// final newState = loadedState.copyWith(
///   user: updatedUser,
/// );
/// ```
@StateModel()
sealed class UserState with _$UserState {
  const UserState._();

  /// Initial state before any action.
  const factory UserState.initial() = UserStateInitial;

  /// Loading state during async operations.
  const factory UserState.loading() = UserStateLoading;

  /// Loaded state with user data.
  const factory UserState.loaded({required Character user}) = UserStateLoaded;

  /// State with a list of users.
  const factory UserState.userList({required List<Character> users}) =
      UserStateUserList;

  /// Error state with message.
  const factory UserState.error({required String message}) = UserStateError;
}
