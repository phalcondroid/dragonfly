// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

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
      final Map<String, Object?> response = await network.callForObject(
        HttpMethods.get,
        'character',
        null,
        null,
      );

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
        (json) => Character.fromJson(json as Map<String, Object?>),
      );
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
      final Map<String, Object?> response = await network.callForObject(
        HttpMethods.get,
        'character',
        null,
        null,
      );

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
        (json) => Info.fromJson(json as Map<String, Object?>),
      );
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

  @override
  Stream<Character> onCharacterCreated() {
    final _log = DragonflyLogManager.instance;

    _log.info(
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
        _log.error(
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
    final _log = DragonflyLogManager.instance;

    _log.info(
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
        _log.error(
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
