import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';

part 'location.model.dart';

@FactoryModel()
@ValueObject()
abstract interface class Location implements _$LocationContract {
  factory Location({required String name, required String url}) = _$Location;
  factory Location.fromJson(Map<String, Object?> value) = _$Location.fromJson;
}
