import 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart';
import 'package:dragonfly/framework/types/enums/http_methods.dart';

abstract interface class DragonflyBaseNetworkAdapter {
  Future<List<Map<String, Object?>>> callForList(
      HttpMethods method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);

  Future<Map<String, Object?>> callForObject(HttpMethods method, String path,
      Map<String, dynamic>? params, DragonflyNetworkOptions? options);
}
