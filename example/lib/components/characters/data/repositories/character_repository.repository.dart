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
    final _log = DragonflyLogManager.instance;
    final _stopwatch = Stopwatch()..start();

    try {
      _log.repositoryStart(
        repository: 'CharacterRepository',
        method: 'getAll',
        params: {'name': name, 'julian': julian},
      );

      final DragonflyNetworkHttpAdapter network = DragonflyContainer.I
          .get<DragonflyNetworkHttpAdapter>(instanceName: 'defaultHttpNetwork');
      final Map<String, Object?> response =
          await network.callForObject(HttpMethods.get, 'character', null, null);

      _stopwatch.stop();
      _log.repositorySuccess(
        repository: 'CharacterRepository',
        method: 'getAll',
        message: 'Operation completed successfully',
        durationMs: _stopwatch.elapsedMilliseconds,
        params: {'name': name, 'julian': julian},
      );

      return ServiceResponse<Character>.fromJson(
          response as Map<String, Object?>,
          (json) => Character.fromJson(json as Map<String, Object?>));
    } catch (e, stackTrace) {
      _stopwatch.stop();
      _log.repositoryError(
        repository: 'CharacterRepository',
        method: 'getAll',
        message: 'Operation failed',
        error: e,
        stackTrace: stackTrace,
        durationMs: _stopwatch.elapsedMilliseconds,
        params: {'name': name, 'julian': julian},
      );
      rethrow;
    }
  }

  @override
  Future<ServiceResponseDouble<Character, Info>> getAllDouble(
    String name,
    List<String> julian,
  ) async {
    final _log = DragonflyLogManager.instance;
    final _stopwatch = Stopwatch()..start();

    try {
      _log.repositoryStart(
        repository: 'CharacterRepository',
        method: 'getAllDouble',
        params: {'name': name, 'julian': julian},
      );

      final DragonflyNetworkHttpAdapter network = DragonflyContainer.I
          .get<DragonflyNetworkHttpAdapter>(instanceName: 'defaultHttpNetwork');
      final Map<String, Object?> response =
          await network.callForObject(HttpMethods.get, 'character', null, null);

      _stopwatch.stop();
      _log.repositorySuccess(
        repository: 'CharacterRepository',
        method: 'getAllDouble',
        message: 'Operation completed successfully',
        durationMs: _stopwatch.elapsedMilliseconds,
        params: {'name': name, 'julian': julian},
      );

      return ServiceResponseDouble<Character, Info>.fromJson(
          response as Map<String, Object?>,
          (json) => Character.fromJson(json as Map<String, Object?>),
          (json) => Info.fromJson(json as Map<String, Object?>));
    } catch (e, stackTrace) {
      _stopwatch.stop();
      _log.repositoryError(
        repository: 'CharacterRepository',
        method: 'getAllDouble',
        message: 'Operation failed',
        error: e,
        stackTrace: stackTrace,
        durationMs: _stopwatch.elapsedMilliseconds,
        params: {'name': name, 'julian': julian},
      );
      rethrow;
    }
  }
}
