import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:dragonfly/dragonfly.dart';

part 'character_search_state_manager.state_manager.dart';

/// Easy-mode state manager: no `@StateModel` — the sealed state class
/// (`CharacterSearchStateManagerState`) is generated from the `@Event`
/// methods. The method name becomes the variant and the return value becomes
/// its payload; throwing emits the built-in `error` variant.
@StateManager()
class CharacterSearchStateManager {
  CharacterSearchStateManager(@Inject('GetUserList') this._getUserListUseCase);

  final GetUserListUseCase _getUserListUseCase;

  /// Produces the `search({required List<Character> value})` variant.
  @Event(debounce: Duration(milliseconds: 300))
  Future<List<Character>> search(String name) async {
    final result = await _getUserListUseCase.call(name, const []);

    return result.fold(
      (error) => throw Exception(error.toString()),
      (response) => response.results,
    );
  }

  /// Produces the zero-payload `clear()` variant.
  @Event()
  Future<void> clear() async {}
}
