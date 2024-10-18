import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';
import 'package:user/components/characters/data/models/character.dart';
import 'package:user/components/characters/data/models/origin.dart';

part 'service_response.model.dart';

@FactoryModel(generic: true)
abstract interface class ServiceResponse<T, R>
    implements _$ServiceResponseContract<T, R> {
  factory ServiceResponse({
    required Map<String, Object?> info,
    required List<R> result,
    required List<T> res,
  }) = _$ServiceResponse;

  factory ServiceResponse.fromJson(
      Map<String, Object?> value,
      T Function(Object? json) fromJsonT,
      R Function(Object? json) fromJsonR) = _$ServiceResponse.fromJson;
}

void main() {
  final response = ServiceResponse<Character, Origin>.fromJson({
    "info": {"url": "http://alguna.com"},
    "result": [
      {"name": "origin 1"},
      {"name": "origin 2"}
    ],
    "res": [
      {"location": "location 1"},
      {"location": "location 2"}
    ]
  }, (Object? raw) {
    print("===>>>>> Calling T: $raw");
    return Character.fromJson(raw as Map<String, Object?>);
  }, (Object? raw) {
    print("===>>>>> Calling R: $raw");
    return Origin.fromJson(raw as Map<String, Object?>);
  });
}
