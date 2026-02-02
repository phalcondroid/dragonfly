import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';
import 'package:flutter/material.dart';

part 'character_feature.feature.dart';

@DragonflyFeature(logging: true)
class CharacterFeature extends Feature<CharacterState>
    with _$CharacterFeatureMixin {
  CharacterFeature(@Inject('GetUserList') this._getUserListUseCase)
    : super(const CharacterState.initial());

  final GetUserListUseCase _getUserListUseCase;

  @FeatureAction()
  Future<void> fetchCharacter(int id) async {
    emit(const CharacterState.loading());

    final result = await _getUserListUseCase.call("Rick", ["$id"]);

    result.fold(
      (error) => emit(CharacterState.error(message: error.toString())),
      (response) {
        final characters = response.results;
        if (characters.isNotEmpty) {
          emit(CharacterState.loaded(character: characters.first));
        } else {
          emit(const CharacterState.error(message: 'No characters found'));
        }
      },
    );
  }

  @FeatureAction()
  Future<void> fetchAllCharacters() async {
    emit(const CharacterState.loading());

    final result = await _getUserListUseCase.call("Rick", ["1", "2", "3"]);

    result.fold(
      (error) => emit(CharacterState.error(message: error.toString())),
      (response) {
        emit(CharacterState.characterList(characters: response.results));
      },
    );
  }

  @FeatureAction()
  Future<void> deleteCharacter(Character character) async {
    emit(const CharacterState.loading());

    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const CharacterState.initial());
      sideEffect(const ShowSnackbar('Character deleted successfully'));
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  @FeatureAction()
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

  @FeatureAction()
  void refresh() {
    state.maybeWhen(
      loaded: (character) => fetchCharacter(character.id),
      orElse: () => fetchCharacter(1),
    );
  }

  @FeatureAction()
  void reset() {
    emit(const CharacterState.initial());
  }
}
