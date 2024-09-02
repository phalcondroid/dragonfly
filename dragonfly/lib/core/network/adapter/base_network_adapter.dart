import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';

abstract interface class BaseNetworkAdapter<Request, Response> {
  Response call(String path, Request params, HttpAnnotations? networkMethod);
}
