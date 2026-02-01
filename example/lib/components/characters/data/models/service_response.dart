import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/data/models/info.dart';

part 'service_response.model.dart';

/// Generic service response model for API responses.
///
/// This model can be used with any data type. For example:
/// ```dart
/// // For character list response
/// ServiceResponse<Character>.fromJson(
///   json,
///   (e) => Character.fromJson(e as Map<String, Object?>),
/// );
///
/// // For location list response
/// ServiceResponse<Location>.fromJson(
///   json,
///   (e) => Location.fromJson(e as Map<String, Object?>),
/// );
/// ```
///
/// Example JSON:
/// ```json
/// {
///   "info": {
///     "count": 826,
///     "pages": 42,
///     "next": "https://api.example.com/data?page=2",
///     "prev": null
///   },
///   "results": [...]
/// }
/// ```
@FactoryModel(
  generic: true,
  toJson: true,
  toMap: true,
  equals: true,
  toStringMethod: true,
)
abstract interface class ServiceResponse<T>
    implements _$ServiceResponseContract<T> {
  factory ServiceResponse({required Info info, required List<T> results}) =
      _$ServiceResponse;

  factory ServiceResponse.fromJson(
    Map<String, Object?> value,
    T Function(Object? json) fromJsonT,
  ) = _$ServiceResponse.fromJson;
}
