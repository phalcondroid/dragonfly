import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';

part 'paginated_response.model.dart';

/// Generic paginated response model with two type parameters.
///
/// This model supports two generic types:
/// - `I` - The info/metadata type
/// - `T` - The result item type
///
/// Usage example:
/// ```dart
/// // Using with Info and Character
/// final response = PaginatedResponse<Info, Character>.fromJson(
///   json,
///   (e) => Info.fromJson(e as Map<String, Object?>),
///   (e) => Character.fromJson(e as Map<String, Object?>),
/// );
///
/// // Using with CustomMeta and Location
/// final locations = PaginatedResponse<CustomMeta, Location>.fromJson(
///   json,
///   (e) => CustomMeta.fromJson(e as Map<String, Object?>),
///   (e) => Location.fromJson(e as Map<String, Object?>),
/// );
/// ```
///
/// Example JSON structure:
/// ```json
/// {
///   "info": {
///     "count": 826,
///     "pages": 42,
///     "next": "https://api.example.com/resource?page=2",
///     "prev": null
///   },
///   "results": [
///     { ... },
///     { ... }
///   ]
/// }
/// ```
@FactoryModel(
  generic: true,
  toJson: true,
  toMap: true,
  equals: true,
  toStringMethod: true,
)
abstract interface class PaginatedResponse<I, T>
    implements _$PaginatedResponseContract<I, T> {
  factory PaginatedResponse({
    required I info,
    required List<T> results,
  }) = _$PaginatedResponse;

  factory PaginatedResponse.fromJson(
    Map<String, Object?> json,
    I Function(Object? json) fromJsonI,
    T Function(Object? json) fromJsonT,
  ) = _$PaginatedResponse.fromJson;
}
