import 'package:user/characters/contracts/character_contract.dart';

abstract interface class CharacterRepositoryContract {
  Future<List<CharacterContract>> getAll();
}
