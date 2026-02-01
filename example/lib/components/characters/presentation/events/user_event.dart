import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';

part 'user_event.event.dart';

/// Example event model for BLoC pattern.
///
/// Usage:
/// ```dart
/// // Create events
/// final loadingEvent = UserEvent.loading();
/// final fetchEvent = UserEvent.fetchUser(userId: 1);
/// final deleteEvent = UserEvent.deleteUser(user: someUser);
///
/// // Pattern matching with when
/// event.when(
///   loading: () => print('Loading...'),
///   fetchUser: (userId) => print('Fetching user $userId'),
///   deleteUser: (user) => print('Deleting ${user.name}'),
/// );
///
/// // Pattern matching with maybeWhen
/// event.maybeWhen(
///   loading: () => print('Loading...'),
///   orElse: () => print('Other event'),
/// );
///
/// // Type-safe pattern matching with map
/// final widget = event.map(
///   loading: (e) => CircularProgressIndicator(),
///   fetchUser: (e) => Text('Fetching ${e.userId}'),
///   deleteUser: (e) => Text('Deleting ${e.user.name}'),
/// );
/// ```
@EventModel()
sealed class UserEvent with _$UserEvent {
  const UserEvent._();

  /// Event to indicate loading state.
  const factory UserEvent.loading() = UserEventLoading;

  /// Event to fetch a user by ID.
  const factory UserEvent.fetchUser({required int userId}) = UserEventFetchUser;

  /// Event to delete a user.
  const factory UserEvent.deleteUser({required Character user}) =
      UserEventDeleteUser;

  /// Event to update a user.
  const factory UserEvent.updateUser({
    required Character user,
    required String newName,
  }) = UserEventUpdateUser;
}
