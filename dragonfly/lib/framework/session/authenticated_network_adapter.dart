import 'package:dragonfly/framework/network/adapter/dragonfly_network_http_adapter.dart';
import 'package:dragonfly/framework/session/dragonfly_session_manager.dart';
import 'package:http/http.dart' as http;

/// Network adapter that automatically injects authentication tokens.
///
/// Extends the standard HTTP adapter with three hooks: the session token is
/// merged into [buildHeaders], an optional token refresh runs
/// [beforeRequest], and a 401 response triggers [onTokenExpired] (or a
/// default logout) in [afterResponse].
///
/// Generated repository methods route here when the method is annotated with
/// `@Authenticated()` — the adapter is registered under
/// `'<connectionName>:authenticated'` by `DragonflyInstanceConfig`.
class AuthenticatedNetworkAdapter extends DragonflyNetworkHttpAdapter {
  /// Custom token type override.
  final String? tokenTypeOverride;

  /// Custom auth header name override.
  final String? authHeaderOverride;

  /// Callback when token is expired/invalid (401 response).
  final Future<void> Function()? onTokenExpired;

  /// Callback to refresh token before request.
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

    // Add authentication header if session is active
    if (_session.isAuthenticated && _session.token != null) {
      final tokenType = tokenTypeOverride ?? _session.config.tokenType;
      final headerName = authHeaderOverride ?? _session.config.authHeaderName;
      merged[headerName] = '$tokenType ${_session.token}';
    }

    return merged;
  }

  @override
  Future<void> beforeRequest() async {
    // Check if token needs refresh
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
      await _handleUnauthorized();
    }
  }

  /// Handle 401 Unauthorized responses
  Future<void> _handleUnauthorized() async {
    if (onTokenExpired != null) {
      await onTokenExpired!();
    } else {
      // Default behavior: logout
      await _session.logout();
    }
  }
}
