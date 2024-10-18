// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_repository.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

class _CharacterRepository implements CharacterRepository {
  @override
  Future<List<Character>> getAll(
    String name,
    List<String> julian,
  ) async {
    final DragonflyNetworkHttpAdapter network =
        DragonflyInjector.get<DragonflyNetworkHttpAdapter>(
            '__df_network_default');
    print(network);
    final List<Map<String, Object?>> response = await network.callForList(
        HttpMethods.post,
        'https://rickandmortyapi.com/api/character',
        null,
        null);
    return Character;
  }
}
