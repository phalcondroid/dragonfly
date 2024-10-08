import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_annotations/enums/network_adapter.dart';
import 'package:user/characters/contracts/character_repository_contract.dart';
import 'package:user/characters/factories/character.dart';
import 'package:dragonfly/dragonfly.dart';

part "character_repository.repository.dart";

@Repository(adapter: NetworkAdapter.http)
abstract class CharacterRepository
    implements CharacterRepositoryContract<Character> {
  factory CharacterRepository() = _CharacterRepository;

  @override
  @Post(path: 'julian/url', headers: {"cabeza-julian": "jajajja"})
  Future<List<Character>> getAll(
      @Path() String name, @Query() List<String> julian);
}
