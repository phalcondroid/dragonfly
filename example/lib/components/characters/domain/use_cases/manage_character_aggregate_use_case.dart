import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/data/repositories/character_repository.dart';

/// Demonstrates DDD aggregate logic over the [Character] aggregate root.
///
/// [Character] is annotated `@Aggregate(identityField: 'id')`, so the generated
/// `_$Character` implements `AggregateRoot<int>` with:
/// - `int get identity` — the unique identifier
/// - `bool sameIdentityAs(Object other)` — identity comparison (ignores fields)
/// - identity-based `==` and `hashCode` — only `id` participates
@UseCase(instanceName: 'ManageCharacterAggregate')
class ManageCharacterAggregateUseCase {
  final CharacterRepository repository;

  const ManageCharacterAggregateUseCase(this.repository);

  /// Loads two representations of the same aggregate and proves that identity
  /// equality ignores differing field values.
  Future<bool> demonstrateIdentitySemantics(int characterId) async {
    final fromApi = await repository.getById(characterId);
    if (fromApi == null) return false;

    // Build a skeletal representation: same id, different fields.
    final skeletal = Character.fromJson({
      'id': characterId,
      'name': '',
      'status': '',
      'species': '',
      'image': '',
      'type': '',
      'gender': '',
      'origin': null,
      'location': null,
      'episode': <String>[],
      'url': '',
      'created': '',
    });

    // 1. sameIdentityAs — identity comparison via the AggregateRoot contract.
    //    Cast to the contract interface; the generated _$Character implements it.
    final a = fromApi as AggregateRoot<int>;
    final b = skeletal as AggregateRoot<int>;
    final sameEntity = a.sameIdentityAs(b);               // true

    // 2. Identity-based equality — == uses only id. Even though name,
    //    status, image, etc. differ, the entities are equal.
    final equalsById = fromApi == skeletal;               // true

    // 3. The AggregateRoot<int> contract gives typed identity access.
    final int id = a.identity;                            // typed getter

    return sameEntity && equalsById && id == characterId;
  }

  /// Persists a character through the `@Post` method on the repository.
  /// The runtime API (Rick & Morty) is read-only; the generated code
  /// demonstrates the wire format — `toJson()` as the body + auth adapter.
  Future<Character> saveCharacter(Character character) async {
    return repository.createCharacter(character);
  }
}
