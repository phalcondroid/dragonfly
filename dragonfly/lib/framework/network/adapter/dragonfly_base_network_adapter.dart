import 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart';
import 'package:dragonfly/framework/types/enums/http_methods.dart';

/// Contract every network transport adapter must fulfill.
///
/// Built-in implementations:
/// - [DragonflyNetworkHttpAdapter] — HTTP/S request/response
/// - [DragonflyWebSocketAdapter] — WebSocket streaming + pub/sub
///
/// Community adapters (WebRTC, gRPC, GraphQL, MQTT, etc.) implement this
/// interface and are registered through [DragonflyAdapterConfig].
///
/// ### Hook methods
///
/// [beforeRequest], [afterResponse] and [buildHeaders] let adapters and
/// decorators inject behavior around every request — token refresh,
/// authentication headers, logging, caching. Override them in your adapter
/// or in a decorator that wraps this adapter.
///
/// The built-in [DragonflyAuthenticatedAdapter] uses these hooks to manage
/// session tokens and works with *any* [DragonflyBaseNetworkAdapter].
abstract class DragonflyBaseNetworkAdapter {
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

  // ── Hooks — override to inject behavior around every request ──────────────

  /// Called before the request is sent. Use for token refresh,
  /// pre-flight checks, or metrics collection.
  ///
  /// Default: no-op.
  Future<void> beforeRequest() async {}

  /// Called after a response is received. Use for 401 handling,
  /// response caching, or metrics.
  ///
  /// The [response] type is transport-specific — [http.Response] for
  /// HTTP adapters, a raw map for WebSocket messages. Override with
  /// the transport-appropriate type.
  ///
  /// Default: no-op.
  Future<void> afterResponse(covariant dynamic response) async {}

  /// Builds the final headers map for a request. Override to inject
  /// authentication tokens, trace IDs, or custom headers.
  ///
  /// [headers] — the per-request headers (from `@Header` annotations).
  /// Default: returns [headers] unchanged (or an empty map if null).
  Map<String, String> buildHeaders(Map<String, String>? headers) =>
      headers ?? {};

  // ── Lifecycle (optional) ──────────────────────────────────────────────────

  /// Opens the connection. Safe to call when already connected.
  Future<void> connect() async {}

  /// Closes the connection and completes open subscriptions.
  Future<void> disconnect() async {}
}
