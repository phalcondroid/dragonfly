import 'package:user/characters/contracts/character_contract.dart';

abstract interface class CharacterRepositoryContract<
    C extends CharacterContract> {
  Future<List<C>> getAll(String name, List<String> julian);
}
