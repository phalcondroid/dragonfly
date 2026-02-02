import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';

part 'character_state.state.dart';

@StateModel()
sealed class CharacterState with _$CharacterState {
  const CharacterState._();

  const factory CharacterState.initial() = CharacterStateInitial;

  const factory CharacterState.loading() = CharacterStateLoading;

  const factory CharacterState.loaded({required Character character}) =
      CharacterStateLoaded;

  const factory CharacterState.characterList({
    required List<Character> characters,
  }) = CharacterStateCharacterList;

  const factory CharacterState.error({required String message}) =
      CharacterStateError;
}
