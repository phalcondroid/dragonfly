import 'package:user/characters/contracts/character_contract.dart';

class Character implements CharacterContract {
  @override
  final String id;

  @override
  final String name;

  @override
  final String specie;

  const Character({
    required this.id,
    required this.name,
    required this.specie
  });
}
