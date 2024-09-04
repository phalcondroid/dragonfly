import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly/core/network/adapter/dragonfly_network_options.dart';

abstract interface class DragonflyBaseNetworkAdapter {
  Future<List<Map<String, Object?>>> callForComplexResultset(
      HttpAnnotations method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);

  Future<Map<String, Object?>> callForSimpleResultset(
      HttpAnnotations method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);
}
