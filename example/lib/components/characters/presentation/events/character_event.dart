import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';

part 'character_event.event.dart';

@EventModel()
sealed class CharacterEvent with _$CharacterEvent {
  const CharacterEvent._();

  const factory CharacterEvent.loading() = CharacterEventLoading;

  const factory CharacterEvent.fetch({required int characterId}) =
      CharacterEventFetch;

  const factory CharacterEvent.delete({required Character character}) =
      CharacterEventDelete;

  const factory CharacterEvent.update({
    required Character character,
    required String newName,
  }) = CharacterEventUpdate;
}
