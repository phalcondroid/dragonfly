import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:user/components/characters/data/models/origin.dart';

part 'character.model.dart';

@FactoryModel()
abstract interface class Character {
  factory Character(
      {@Field(field: "id", value: 123) required int id,
      required String name,
      required bool status,
      required String species,
      required String type,
      required String gender,
      required Origin origin,
      required String location,
      required String image,
      required List<String> episode,
      required String url,
      required String created,
      required Set<Origin> setObj,
      required final Map<String, int> map,
      final Object? obj,
      required List<Object?> devices}) = _$Character;

  factory Character.fromJson(Map<String, Object?> value) = _$Character.fromJson;
}
