import 'package:dragonfly_annotations/annotations/repository.dart';
import 'package:dragonfly_annotations/enums/network_adapter.dart';
import 'package:user/characters/contracts/character_repository_contract.dart';
import 'package:user/characters/factories/character.dart';

part "character_repository.g.dart";

@Repository(adapter: NetworkAdapter.http)
abstract class CharacterRepository implements CharacterRepositoryContract {
  factory CharacterRepository() = _CharacterRepository;

  @override
  Future<List<Character>> getAll();
}
