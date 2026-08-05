import 'enums/http_annotations.dart';
import 'headers_type.dart';
import 'params_type.dart';
import 'return_type.dart';

class MethodRepositoryType {
  final String name;
  final String path;
  final String connection;
  final bool cached;
  final HttpAnnotations type;
  final List<ParamsType> params;
  final ReturnType returnType;
  final List<HeadersType> headers;
  final bool isFuture;

  /// Realtime channel for @Subscribe methods; empty for HTTP methods.
  final String channel;

  const MethodRepositoryType(
      {required this.name,
      required this.path,
      required this.type,
      required this.params,
      required this.returnType,
      required this.isFuture,
      this.channel = '',
      this.connection = "default",
      this.cached = false,
      this.headers = const []});
}
