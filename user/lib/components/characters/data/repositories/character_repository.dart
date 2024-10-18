import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_annotations/enums/network_adapter.dart';
import 'package:dragonfly/dragonfly.dart';
import 'package:user/components/characters/data/models/character.dart';

part "character_repository.repository.dart";

@Repository(adapter: NetworkAdapter.http)
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  @Post(
    path:
        'https://rickandmortyapi.com/api/character', /*headers: {"cabeza-julian": "jajajja"}*/
  )
  Future<List<Character>> getAll(
      @Path() String name, @Query() List<String> julian);
}
