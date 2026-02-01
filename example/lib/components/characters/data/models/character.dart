import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/location.dart';
import 'package:example/components/characters/data/models/origin.dart';

part 'character.model.dart';

/// Character model from Rick and Morty API.
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "Rick Sanchez",
///   "status": "Alive",
///   "species": "Human",
///   "type": "",
///   "gender": "Male",
///   "origin": {
///     "name": "Earth",
///     "url": "https://rickandmortyapi.com/api/location/1"
///   },
///   "location": {
///     "name": "Earth",
///     "url": "https://rickandmortyapi.com/api/location/20"
///   },
///   "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
///   "episode": ["https://rickandmortyapi.com/api/episode/1"],
///   "url": "https://rickandmortyapi.com/api/character/1",
///   "created": "2017-11-04T18:48:46.250Z"
/// }
/// ```
@FactoryModel(
  toJson: true,
  toMap: true,
  equals: true,
  toStringMethod: true,
  copyWith: true,
)
abstract interface class Character implements _$CharacterContract {
  factory Character({
    @Field(field: "id", value: 0) required int id,
    required String name,
    required String status,
    required String species,
    required String type,
    required String gender,
    required Origin origin,
    required Location location,
    required String image,
    required List<String> episode,
    required String url,
    required String created,
  }) = _$Character;

  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
