import 'package:analyzer/dart/constant/value.dart';
import 'package:dragonfly_builder/builder/types/headers_type.dart';

class HeaderHelper {
  List<HeadersType> fromDartObject2HeaderType(
      Map<DartObject, DartObject>? input) {
    List<HeadersType> headers = [];
    if (input == null) {
      return headers;
    }
    input.forEach((key, value) {
      if (key.toStringValue()!.isNotEmpty &&
          value.toStringValue()!.isNotEmpty) {
        headers.add(HeadersType(
            name: key.toStringValue() ?? "",
            value: value.toStringValue() ?? ""));
      }
    });
    return headers;
  }
}
