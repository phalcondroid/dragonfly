import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';

part 'origin.model.dart';

@FactoryModel()
abstract interface class Origin implements _$OriginContract {
  factory Origin({required String name, required String url}) = _$Origin;
  factory Origin.fromJson(Map<String, Object?> value) = _$Origin.fromJson;
}
