import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/data/models/service_response.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:example/components/characters/presentation/events/character_event.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';

part 'character_bloc.bloc.dart';

@DragonflyBloc(
  event: CharacterEvent,
  state: CharacterState,
  enableLogging: true,
)
class CharacterBloc extends DragonflyBlocBase<CharacterEvent, CharacterState>
    with _$CharacterBlocMixin {
  CharacterBloc(@Inject('GetUserList') this._getUserListUseCase)
    : super(const CharacterState.initial()) {
    on<CharacterEventLoading>(_onLoading);
    on<CharacterEventFetch>(_onFetch);
    on<CharacterEventDelete>(_onDelete);
    on<CharacterEventUpdate>(_onUpdate);
  }

  final GetUserListUseCase _getUserListUseCase;

  Future<void> _onLoading(
    CharacterEventLoading event,
    Emitter<CharacterState> emit,
  ) async {
    emit(const CharacterState.loading());
  }

  Future<void> _onFetch(
    CharacterEventFetch event,
    Emitter<CharacterState> emit,
  ) async {
    emit(const CharacterState.loading());

    final result = await _getUserListUseCase.call("Rick", ["1", "2", "3"]);

    result.fold(
      (error) => emit(CharacterState.error(message: error.toString())),
      (response) {
        final characters = response.results;
        if (characters.isNotEmpty) {
          emit(CharacterState.loaded(character: characters.first));
        } else {
          emit(const CharacterState.error(message: 'No characters found'));
        }
      },
    );
  }

  Future<void> _onDelete(
    CharacterEventDelete event,
    Emitter<CharacterState> emit,
  ) async {
    emit(const CharacterState.loading());

    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const CharacterState.initial());
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  Future<void> _onUpdate(
    CharacterEventUpdate event,
    Emitter<CharacterState> emit,
  ) async {
    emit(const CharacterState.loading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updated = Character(
        id: event.character.id,
        name: event.newName,
        status: event.character.status,
        species: event.character.species,
        type: event.character.type,
        gender: event.character.gender,
        origin: event.character.origin,
        location: event.character.location,
        image: event.character.image,
        episode: event.character.episode,
        url: event.character.url,
        created: event.character.created,
      );

      emit(CharacterState.loaded(character: updated));
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }
}
