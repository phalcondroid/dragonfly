// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'character_repository.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

class _CharacterRepository implements CharacterRepository {
  @override
  Future<ServiceResponse<Character>> getAll(String name) async {
    final log = DragonflyLogManager.instance;
    final stopwatch = Stopwatch()..start();

    try {
      log.repositoryStart(
        repository: 'CharacterRepository',
        method: 'getAll',
        params: {'name': name},
      );

      final DragonflyBaseNetworkAdapter network = DragonflyContainer.I
          .get<DragonflyBaseNetworkAdapter>(instanceName: 'defaultHttpNetwork');
      final Map<String, Object?> response = await network.requestObject(
        HttpMethods.get,
        'character',
        query: {'name': name},
      );

      stopwatch.stop();
      log.repositorySuccess(
        repository: 'CharacterRepository',
        method: 'getAll',
        message: 'Operation completed successfully',
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'name': name},
      );

      return ServiceResponse<Character>.fromJson(
        response as Map<String, Object?>,
        (json) => Character.fromJson(json as Map<String, Object?>),
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      log.repositoryError(
        repository: 'CharacterRepository',
        method: 'getAll',
        message: 'Operation failed',
        error: e,
        stackTrace: stackTrace,
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'name': name},
      );
      rethrow;
    }
  }

  @override
  Future<Character> getById(int id) async {
    final log = DragonflyLogManager.instance;
    final stopwatch = Stopwatch()..start();

    try {
      log.repositoryStart(
        repository: 'CharacterRepository',
        method: 'getById',
        params: {'id': id},
      );

      final DragonflyBaseNetworkAdapter network = DragonflyContainer.I
          .get<DragonflyBaseNetworkAdapter>(instanceName: 'defaultHttpNetwork');
      final Map<String, Object?> response = await network.requestObject(
        HttpMethods.get,
        'character/${id}',
      );

      stopwatch.stop();
      log.repositorySuccess(
        repository: 'CharacterRepository',
        method: 'getById',
        message: 'Operation completed successfully',
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'id': id},
      );

      return Character.fromJson(response as Map<String, Object?>);
    } catch (e, stackTrace) {
      stopwatch.stop();
      log.repositoryError(
        repository: 'CharacterRepository',
        method: 'getById',
        message: 'Operation failed',
        error: e,
        stackTrace: stackTrace,
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<ServiceResponseDouble<Character, Info>> getAllDouble(
    String name,
    List<String> params,
  ) async {
    final log = DragonflyLogManager.instance;
    final stopwatch = Stopwatch()..start();

    try {
      log.repositoryStart(
        repository: 'CharacterRepository',
        method: 'getAllDouble',
        params: {'name': name, 'params': params},
      );

      final DragonflyBaseNetworkAdapter network = DragonflyContainer.I
          .get<DragonflyBaseNetworkAdapter>(instanceName: 'defaultHttpNetwork');
      final Map<String, Object?> response = await network.requestObject(
        HttpMethods.get,
        'character',
        query: {'name': name, 'ids': params},
      );

      stopwatch.stop();
      log.repositorySuccess(
        repository: 'CharacterRepository',
        method: 'getAllDouble',
        message: 'Operation completed successfully',
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'name': name, 'params': params},
      );

      return ServiceResponseDouble<Character, Info>.fromJson(
        response as Map<String, Object?>,
        (json) => Character.fromJson(json as Map<String, Object?>),
        (json) => Info.fromJson(json as Map<String, Object?>),
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      log.repositoryError(
        repository: 'CharacterRepository',
        method: 'getAllDouble',
        message: 'Operation failed',
        error: e,
        stackTrace: stackTrace,
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'name': name, 'params': params},
      );
      rethrow;
    }
  }

  @override
  Future<Character> createCharacter(Character character) async {
    final log = DragonflyLogManager.instance;
    final stopwatch = Stopwatch()..start();

    try {
      log.repositoryStart(
        repository: 'CharacterRepository',
        method: 'createCharacter',
        params: {'character': character},
      );

      final DragonflyBaseNetworkAdapter network = DragonflyContainer.I
          .get<DragonflyBaseNetworkAdapter>(
            instanceName: 'defaultHttpNetwork:authenticated',
          );
      final Map<String, Object?> response = await network.requestObject(
        HttpMethods.post,
        'character',
        body: character.toJson(),
      );

      stopwatch.stop();
      log.repositorySuccess(
        repository: 'CharacterRepository',
        method: 'createCharacter',
        message: 'Operation completed successfully',
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'character': character},
      );

      return Character.fromJson(response as Map<String, Object?>);
    } catch (e, stackTrace) {
      stopwatch.stop();
      log.repositoryError(
        repository: 'CharacterRepository',
        method: 'createCharacter',
        message: 'Operation failed',
        error: e,
        stackTrace: stackTrace,
        durationMs: stopwatch.elapsedMilliseconds,
        params: {'character': character},
      );
      rethrow;
    }
  }

  @override
  Stream<Character> onCharacterCreated() {
    final log = DragonflyLogManager.instance;

    log.info(
      'Subscribing to character.created',
      source: 'CharacterRepository.onCharacterCreated',
      data: null,
    );

    final DragonflyRealtimeAdapter realtime = DragonflyContainer.I
        .get<DragonflyRealtimeAdapter>(instanceName: 'events');

    return realtime.subscribeToObject('character.created', params: null).map((
      Map<String, Object?> event,
    ) {
      try {
        return Character.fromJson(event);
      } catch (e, stackTrace) {
        log.error(
          'Failed to deserialize a character.created event',
          error: e,
          stackTrace: stackTrace,
          source: 'CharacterRepository.onCharacterCreated',
        );
        rethrow;
      }
    });
  }

  @override
  Stream<List<Character>> onCharacterBatch() {
    final log = DragonflyLogManager.instance;

    log.info(
      'Subscribing to onCharacterBatch',
      source: 'CharacterRepository.onCharacterBatch',
      data: null,
    );

    final DragonflyRealtimeAdapter realtime = DragonflyContainer.I
        .get<DragonflyRealtimeAdapter>(instanceName: 'events');

    return realtime.subscribeToList('onCharacterBatch', params: null).map((
      List<Map<String, Object?>> event,
    ) {
      try {
        return event.map((e) => Character.fromJson(e)).toList();
      } catch (e, stackTrace) {
        log.error(
          'Failed to deserialize a onCharacterBatch event',
          error: e,
          stackTrace: stackTrace,
          source: 'CharacterRepository.onCharacterBatch',
        );
        rethrow;
      }
    });
  }
}
