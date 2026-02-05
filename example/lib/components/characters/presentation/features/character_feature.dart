import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';
import 'package:flutter/material.dart';

part 'character_feature.state_manager.dart';

@DragonflyStateManager(logging: true)
class CharacterFeature extends StateManager<CharacterState>
    with _$CharacterFeatureMixin {
  CharacterFeature(@Inject('GetUserList') this._getUserListUseCase)
    : super(const CharacterState.initial());

  final GetUserListUseCase _getUserListUseCase;

  @StateAction()
  Future<void> fetchCharacter(int id) async {
    final stopwatch = Stopwatch()..start();
    logActionStart('fetchCharacter', {'id': id});

    emit(const CharacterState.loading());

    logStep('Calling UseCase', {
      'name': 'Rick',
      'ids': [id],
    });
    final result = await _getUserListUseCase.call("Rick", ["$id"]);

    result.fold(
      (error) {
        logActionEnd(
          'fetchCharacter',
          durationMs: stopwatch.elapsedMilliseconds,
          success: false,
          error: error.toString(),
        );
        emit(CharacterState.error(message: error.toString()));
      },
      (response) {
        final characters = response.results;
        logStep('Response received', {'count': characters.length});
        if (characters.isNotEmpty) {
          emit(CharacterState.loaded(character: characters.first));
          logActionEnd(
            'fetchCharacter',
            durationMs: stopwatch.elapsedMilliseconds,
          );
        } else {
          logActionEnd(
            'fetchCharacter',
            durationMs: stopwatch.elapsedMilliseconds,
            success: false,
            error: 'No characters found',
          );
          emit(const CharacterState.error(message: 'No characters found'));
        }
      },
    );
  }

  @StateAction()
  Future<void> fetchAllCharacters() async {
    final stopwatch = Stopwatch()..start();
    logActionStart('fetchAllCharacters');

    emit(const CharacterState.loading());

    logStep('Fetching multiple characters');
    final result = await _getUserListUseCase.call("Rick", ["1", "2", "3"]);

    result.fold(
      (error) {
        logActionEnd(
          'fetchAllCharacters',
          durationMs: stopwatch.elapsedMilliseconds,
          success: false,
          error: error.toString(),
        );
        emit(CharacterState.error(message: error.toString()));
      },
      (response) {
        logStep('Characters loaded', {'count': response.results.length});
        emit(CharacterState.characterList(characters: response.results));
        logActionEnd(
          'fetchAllCharacters',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      },
    );
  }

  @StateAction()
  Future<void> deleteCharacter(Character character) async {
    final stopwatch = Stopwatch()..start();
    logActionStart('deleteCharacter', {
      'characterId': character.id,
      'name': character.name,
    });

    emit(const CharacterState.loading());

    try {
      logStep('Simulating delete operation');
      await Future.delayed(const Duration(seconds: 1));
      emit(const CharacterState.initial());
      sideEffect(const ShowSnackbar('Character deleted successfully'));
      logActionEnd(
        'deleteCharacter',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      logActionEnd(
        'deleteCharacter',
        durationMs: stopwatch.elapsedMilliseconds,
        success: false,
        error: e.toString(),
      );
      emit(CharacterState.error(message: e.toString()));
    }
  }

  @StateAction()
  Future<void> updateCharacter(Character character, String newName) async {
    emit(const CharacterState.loading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updated = Character(
        id: character.id,
        name: newName,
        status: character.status,
        species: character.species,
        type: character.type,
        gender: character.gender,
        origin: character.origin,
        location: character.location,
        image: character.image,
        episode: character.episode,
        url: character.url,
        created: character.created,
      );

      emit(CharacterState.loaded(character: updated));
      sideEffect(ShowSnackbar('Updated to $newName'));
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  @StateAction()
  void refresh() {
    state.maybeWhen(
      loaded: (character) => fetchCharacter(character.id),
      orElse: () => fetchCharacter(1),
    );
  }

  @StateAction()
  void reset() {
    emit(const CharacterState.initial());
  }
}
