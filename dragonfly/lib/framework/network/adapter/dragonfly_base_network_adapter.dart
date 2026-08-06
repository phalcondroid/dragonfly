import 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart';
import 'package:dragonfly/framework/types/enums/http_methods.dart';

abstract interface class DragonflyBaseNetworkAdapter {
  /// Legacy single-map call: [params] becomes the query string for
  /// GET/DELETE and the request body otherwise.
  ///
  /// Prefer [requestList], which takes query, body and headers separately.
  Future<List<Map<String, Object?>>> callForList(
      HttpMethods method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options);

  /// Legacy single-map call. Prefer [requestObject].
  Future<Map<String, Object?>> callForObject(HttpMethods method, String path,
      Map<String, dynamic>? params, DragonflyNetworkOptions? options);

  /// Performs a request expecting a JSON array at the top level.
  ///
  /// - [path] may contain `@Path`-substituted segments (already interpolated).
  /// - [query] entries with `null` values are dropped.
  /// - [body] is JSON-encoded as-is for POST/PUT/PATCH/DELETE.
  /// - [headers] are merged over the adapter's configured headers.
  Future<List<Map<String, Object?>>> requestList(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  });

  /// Performs a request expecting a JSON object at the top level.
  /// See [requestList] for parameter semantics.
  Future<Map<String, Object?>> requestObject(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  });
}
