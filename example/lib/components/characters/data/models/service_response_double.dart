import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';

part 'service_response_double.model.dart';

@FactoryModel(generic: true)
abstract interface class ServiceResponseDouble<T, R>
    implements _$ServiceResponseDoubleContract<T, R> {
  factory ServiceResponseDouble({
    required Map<String, Object?> info,
    required List<R> result,
    required T res,
  }) = _$ServiceResponseDouble;

  factory ServiceResponseDouble.fromJson(
    Map<String, Object?> value,
    T Function(Object? json) fromJsonT,
    R Function(Object? json) fromJsonR,
  ) = _$ServiceResponseDouble.fromJson;
}
