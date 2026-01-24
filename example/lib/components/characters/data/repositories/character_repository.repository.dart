// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_repository.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

class _CharacterRepository implements CharacterRepository {
  @override
  Future<ServiceResponse<Character>> getAll(
    String name,
    List<String> julian,
  ) async {
    final DragonflyNetworkHttpAdapter network = DragonflyContainer()
        .get<DragonflyNetworkHttpAdapter>(instanceName: '__http__default');
    final Map<String, Object?> response =
        await network.callForObject(HttpMethods.get, 'character', null, null);
    return ServiceResponse<Character>.fromJson(response as Map<String, Object?>,
        (json) => Character.fromJson(json as Map<String, Object?>));
  }

  @override
  Future<ServiceResponseDouble<Character, Info>> getAllDouble(
    String name,
    List<String> julian,
  ) async {
    final DragonflyNetworkHttpAdapter network = DragonflyContainer()
        .get<DragonflyNetworkHttpAdapter>(instanceName: '__http__default');
    final Map<String, Object?> response =
        await network.callForObject(HttpMethods.get, 'character', null, null);
    return ServiceResponseDouble<Character, Info>.fromJson(
        response as Map<String, Object?>,
        (json) => Character.fromJson(json as Map<String, Object?>),
        (json) => Info.fromJson(json as Map<String, Object?>));
  }
}
