import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';

part 'info.model.dart';

/// Pagination info model.
///
/// Contains metadata about paginated API responses.
///
/// Example JSON:
/// ```json
/// {
///   "count": 826,
///   "pages": 42,
///   "next": "https://api.example.com/resource?page=2",
///   "prev": "https://api.example.com/resource?page=1"
/// }
/// ```
@FactoryModel(
  toJson: true,
  toMap: true,
  equals: true,
  toStringMethod: true,
)
abstract interface class Info implements _$InfoContract {
  factory Info({
    required int count,
    required int pages,
    String? next,
    String? prev,
  }) = _$Info;

  factory Info.fromJson(Map<String, Object?> value) = _$Info.fromJson;
}
