import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/data/repositories/character_repository.dart';
import 'package:example/components/characters/presentation/events/user_event.dart';
import 'package:example/components/characters/presentation/states/user_state.dart';

part 'character_bloc.bloc.dart';

/// BLoC for managing character/user state.
///
/// This BLoC handles events related to user operations and emits
/// corresponding states that the UI can react to.
///
/// Example usage:
/// ```dart
/// // In a widget
/// final bloc = context.bloc<CharacterBloc>();
///
/// // Dispatch events
/// bloc.add(const UserEvent.loading());
/// bloc.add(UserEvent.fetchUser(userId: 1));
///
/// // Listen to state changes
/// DragonflyBlocBuilder<CharacterBloc, UserState>(
///   builder: (context, state) {
///     return state.when(
///       initial: () => Text('Welcome'),
///       loading: () => CircularProgressIndicator(),
///       loaded: (user) => Text(user.name),
///       error: (message) => Text('Error: $message'),
///     );
///   },
/// )
/// ```
@DragonflyBlocAnnotation(
  event: UserEvent,
  state: UserState,
  enableLogging: true,
)
class CharacterBloc extends DragonflyBloc<UserEvent, UserState>
    with _$CharacterBlocMixin {
  CharacterBloc(this._characterRepository) : super(const UserState.initial()) {
    // Register event handlers
    on<UserEventLoading>(_onLoading);
    on<UserEventFetchUser>(_onFetchUser);
    on<UserEventDeleteUser>(_onDeleteUser);
    on<UserEventUpdateUser>(_onUpdateUser);
  }

  final CharacterRepository _characterRepository;

  /// Handle loading event.
  Future<void> _onLoading(
    UserEventLoading event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserState.loading());
  }

  /// Handle fetch user event.
  Future<void> _onFetchUser(
    UserEventFetchUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserState.loading());

    try {
      final response = await _characterRepository.getAll("Rick", [
        "1",
        "2",
        "3",
      ]);

      // ServiceResponse has results property with the list of characters
      final characters = response.results;

      if (characters.isNotEmpty) {
        emit(UserState.loaded(user: characters.first));
      } else {
        emit(const UserState.error(message: 'No characters found'));
      }
    } catch (e) {
      emit(UserState.error(message: e.toString()));
    }
  }

  /// Handle delete user event.
  Future<void> _onDeleteUser(
    UserEventDeleteUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserState.loading());

    try {
      // Simulate deletion
      await Future.delayed(const Duration(seconds: 1));
      emit(const UserState.initial());
    } catch (e) {
      emit(UserState.error(message: e.toString()));
    }
  }

  /// Handle update user event.
  Future<void> _onUpdateUser(
    UserEventUpdateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserState.loading());

    try {
      // Simulate update - in real app, call repository
      await Future.delayed(const Duration(milliseconds: 500));

      // Create updated user (using copyWith if available)
      final updatedUser = Character(
        id: event.user.id,
        name: event.newName,
        status: event.user.status,
        species: event.user.species,
        type: event.user.type,
        gender: event.user.gender,
        origin: event.user.origin,
        location: event.user.location,
        image: event.user.image,
        episode: event.user.episode,
        url: event.user.url,
        created: event.user.created,
      );

      emit(UserState.loaded(user: updatedUser));
    } catch (e) {
      emit(UserState.error(message: e.toString()));
    }
  }
}
