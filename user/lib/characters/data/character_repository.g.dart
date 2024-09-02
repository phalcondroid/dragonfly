// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_repository.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

class _CharacterRepository implements CharacterRepository {
  Future<List<Character>> getAll() {
    final ServiceLocator di = new ServiceLocator();
    final NetworkManager network =
        di.get<NetworkManager>('dragonflyNetworkManager');
  }
}
