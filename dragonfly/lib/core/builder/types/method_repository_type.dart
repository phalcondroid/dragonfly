import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly/core/builder/types/headers_type.dart';
import 'package:dragonfly/core/builder/types/params_type.dart';
import 'package:dragonfly/core/builder/types/return_type.dart';

class MethodRepositoryType {
  final String name;
  final String path;
  final bool cached;
  final HttpAnnotations type;
  final List<ParamsType> params;
  final ReturnType returnType;
  final List<HeadersType> headers;
  final bool isFuture;

  const MethodRepositoryType(
      {required this.name,
      required this.path,
      required this.type,
      required this.params,
      required this.returnType,
      required this.isFuture,
      this.cached = false,
      this.headers = const []});
}
