import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly/core/framework/network/adapter/dragonfly_network_options.dart';

abstract interface class DragonflyBaseNetworkAdapter {
  Future<List<Map<String, Object?>>> callForList(
      HttpAnnotations method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);

  Future<Map<String, Object?>> callForObject(
      HttpAnnotations method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);
}
