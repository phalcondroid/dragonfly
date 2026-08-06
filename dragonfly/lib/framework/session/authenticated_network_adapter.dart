import 'package:dragonfly/framework/network/adapter/dragonfly_base_network_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_http_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart';
import 'package:dragonfly/framework/session/dragonfly_session_manager.dart';
import 'package:dragonfly/framework/types/enums/http_methods.dart';
import 'package:http/http.dart' as http;

/// Decorator that wraps any [DragonflyBaseNetworkAdapter] to inject
/// authentication headers.
///
/// Overrides [DragonflyBaseNetworkAdapter.buildHeaders] to add the session
/// token, [beforeRequest] for optional token refresh, and [afterResponse]
/// for 401 handling.
///
/// Works with any adapter — HTTP, WebSocket, or custom. Generated repository
/// methods route here when annotated with `@Authenticated()` — the adapter is
/// registered under `'$connectionName:authenticated'` by
/// [DragonflyHttpAdapterConfig].
///
/// ```dart
/// // Manually wrapping a custom adapter:
/// final raw = MyCustomAdapter();
/// final auth = DragonflyAuthenticatedAdapter(inner: raw);
/// container.registerSingleton<DragonflyBaseNetworkAdapter>(
///   auth,
///   instanceName: 'myconn:authenticated',
/// );
/// ```
class DragonflyAuthenticatedAdapter
    implements DragonflyBaseNetworkAdapter {
  /// The wrapped adapter that does the actual transport.
  final DragonflyBaseNetworkAdapter inner;

  /// Custom token type override.
  final String? tokenTypeOverride;

  /// Custom auth header name override.
  final String? authHeaderOverride;

  /// Callback when token is expired/invalid (401 response).
  final Future<void> Function()? onTokenExpired;

  /// Callback to refresh token before request.
  final Future<String?> Function()? refreshTokenCallback;

  const DragonflyAuthenticatedAdapter({
    required this.inner,
    this.tokenTypeOverride,
    this.authHeaderOverride,
    this.onTokenExpired,
    this.refreshTokenCallback,
  });

  DragonflySessionManager get _session => DragonflySessionManager.instance;

  // ── Hooks ─────────────────────────────────────────────────────────────────

  @override
  Map<String, String> buildHeaders(Map<String, String>? headers) {
    final merged = inner.buildHeaders(headers);

    if (_session.isAuthenticated && _session.token != null) {
      final tokenType = tokenTypeOverride ?? _session.config.tokenType;
      final headerName = authHeaderOverride ?? _session.config.authHeaderName;
      merged[headerName] = '$tokenType ${_session.token}';
    }

    return merged;
  }

  @override
  Future<void> beforeRequest() async {
    await inner.beforeRequest();

    if (refreshTokenCallback != null && _session.isExpired) {
      final newToken = await refreshTokenCallback!();
      if (newToken != null) {
        await _session.refreshToken(newToken);
      }
    }
  }

  @override
  Future<void> afterResponse(dynamic response) async {
    await inner.afterResponse(response);
  }

  /// Handle 401 Unauthorized responses. Called by adapters that support
  /// HTTP-style status codes.
  Future<void> handleUnauthorized() async {
    if (onTokenExpired != null) {
      await onTokenExpired!();
    } else {
      await _session.logout();
    }
  }

  // ── Delegated transport ───────────────────────────────────────────────────

  @override
  Future<List<Map<String, Object?>>> callForList(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) {
    return inner.callForList(method, path, params, options);
  }

  @override
  Future<Map<String, Object?>> callForObject(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) {
    return inner.callForObject(method, path, params, options);
  }

  @override
  Future<List<Map<String, Object?>>> requestList(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    await beforeRequest();
    final h = buildHeaders(headers);
    try {
      final result = await inner.requestList(method, path,
          query: query, body: body, headers: h);
      await afterResponse(result);
      return result;
    } on Object {
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>> requestObject(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    await beforeRequest();
    final h = buildHeaders(headers);
    try {
      final result = await inner.requestObject(method, path,
          query: query, body: body, headers: h);
      await afterResponse(result);
      return result;
    } on Object {
      rethrow;
    }
  }

  @override
  Future<void> connect() => inner.connect();

  @override
  Future<void> disconnect() => inner.disconnect();
}

// ── Backward-compatible alias ───────────────────────────────────────────────

/// Deprecated — use [DragonflyAuthenticatedAdapter] instead.
@Deprecated('Use DragonflyAuthenticatedAdapter')
class AuthenticatedNetworkAdapter extends DragonflyNetworkHttpAdapter {
  final String? tokenTypeOverride;
  final String? authHeaderOverride;
  final Future<void> Function()? onTokenExpired;
  final Future<String?> Function()? refreshTokenCallback;

  const AuthenticatedNetworkAdapter({
    required super.config,
    super.enableLogging,
    this.tokenTypeOverride,
    this.authHeaderOverride,
    this.onTokenExpired,
    this.refreshTokenCallback,
  });

  DragonflySessionManager get _session => DragonflySessionManager.instance;

  @override
  String get logSource => 'AuthenticatedNetworkAdapter';

  @override
  Map<String, String> buildHeaders(Map<String, String>? headers) {
    final merged = super.buildHeaders(headers);

    if (_session.isAuthenticated && _session.token != null) {
      final tokenType = tokenTypeOverride ?? _session.config.tokenType;
      final headerName = authHeaderOverride ?? _session.config.authHeaderName;
      merged[headerName] = '$tokenType ${_session.token}';
    }

    return merged;
  }

  @override
  Future<void> beforeRequest() async {
    if (refreshTokenCallback != null && _session.isExpired) {
      final newToken = await refreshTokenCallback!();
      if (newToken != null) {
        await _session.refreshToken(newToken);
      }
    }
  }

  @override
  Future<void> afterResponse(http.Response response) async {
    if (response.statusCode == 401) {
      if (onTokenExpired != null) {
        await onTokenExpired!();
      } else {
        await _session.logout();
      }
    }
  }
}
