import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';

part 'character_state_manager.state_manager.dart';

/// StateModel-mode state manager: every `@Event` returns the next
/// [CharacterState] directly. `loading` is emitted automatically before the
/// body runs (the model declares a zero-arg `loading` factory), and a thrown
/// exception is emitted through `error({required String message})`.
@StateManager(state: CharacterState, logging: true)
class CharacterStateManager {
  CharacterStateManager(@Inject('GetUserList') this._getUserListUseCase);

  final GetUserListUseCase _getUserListUseCase;

  @Event()
  Future<CharacterState> fetchCharacter(int id) async {
    final result = await _getUserListUseCase.call("Rick", ["$id"]);

    return result.fold(
      (error) => CharacterState.error(message: error.toString()),
      (response) {
        final characters = response.results;
        if (characters.isEmpty) {
          return const CharacterState.error(message: 'No characters found');
        }
        return CharacterState.loaded(character: characters.first);
      },
    );
  }

  @Event()
  Future<CharacterState> fetchAllCharacters() async {
    final result = await _getUserListUseCase.call("Rick", ["1", "2", "3"]);

    return result.fold(
      (error) => CharacterState.error(message: error.toString()),
      (response) =>
          CharacterState.characterList(characters: response.results),
    );
  }

  @Event()
  Future<CharacterState> deleteCharacter(Character character) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CharacterState.initial();
  }

  @Event()
  Future<CharacterState> updateCharacter(
    Character character,
    String newName,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return CharacterState.loaded(
      character: Character(
        id: character.id,
        name: newName,
        status: character.status,
        species: character.species,
        type: character.type,
        gender: character.gender,
        origin: character.origin,
        location: character.location,
        image: character.image,
        episode: character.episode,
        url: character.url,
        created: character.created,
      ),
    );
  }

  @Event()
  Future<CharacterState> reset() async => const CharacterState.initial();

  /// Typing-driven search. The debounce is applied by the generated
  /// controller, so the view can call `searchByName(query)` on every
  /// keystroke and only the last one within 300ms reaches the network.
  @Event(debounce: Duration(milliseconds: 300))
  Future<CharacterState> searchByName(String name) async {
    final result = await _getUserListUseCase.call(name, const []);

    return result.fold(
      (error) => CharacterState.error(message: error.toString()),
      (response) =>
          CharacterState.characterList(characters: response.results),
    );
  }

  /// Guarded against double taps by a throttle window.
  @Event(throttle: Duration(seconds: 1))
  Future<CharacterState> refreshThrottled() => fetchAllCharacters();
}
