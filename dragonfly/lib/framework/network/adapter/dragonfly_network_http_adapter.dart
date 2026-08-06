import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dragonfly/framework/config/dragonfly_network_config.dart';
import 'package:dragonfly/framework/logging/dragonfly_log_manager.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_base_network_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart';
import 'package:dragonfly/framework/network/exceptions/dragonfly_http_exception.dart';
import 'package:dragonfly/framework/network/exceptions/dragonfly_network_invalid_method_exception.dart';
import 'package:dragonfly/framework/types/enums/http_methods.dart';
import 'package:http/http.dart' as http;

class DragonflyNetworkHttpAdapter implements DragonflyBaseNetworkAdapter {
  final DragonflyNetworkConfig config;

  /// Whether to enable logging for this adapter.
  final bool enableLogging;

  const DragonflyNetworkHttpAdapter({
    required this.config,
    this.enableLogging = true,
  });

  DragonflyLogManager get _log => DragonflyLogManager.instance;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  /// The `source` tag used in log output. Overridden by subclasses.
  @protected
  String get logSource => 'DragonflyNetworkHttpAdapter';

  /// Builds the headers for a request: JSON defaults, then the configured
  /// headers, then the per-request [headers] on top. Overridden by
  /// [DragonflyAuthenticatedAdapter] to inject the session token.
  @protected
  @override
  Map<String, String> buildHeaders(Map<String, String>? headers) {
    final Map<String, String> merged = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (config.headers != null) {
      config.headers!.forEach((key, value) {
        merged[key] = value.toString();
      });
    }

    if (headers != null) {
      merged.addAll(headers);
    }

    return merged;
  }

  /// Hook run before the request is sent (token refresh, etc.).
  @protected
  @override
  Future<void> beforeRequest() async {}

  /// Hook run after a response arrives (401 handling, etc.).
  @protected
  @override
  Future<void> afterResponse(http.Response response) async {}

  /// Build the final URL with query parameters. Entries with `null` values
  /// are dropped.
  Uri _buildUri(String path, Map<String, dynamic>? queryParams) {
    final String baseUrl = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;

    final String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final String fullUrl = "$baseUrl/$cleanPath";

    final query = queryParams?.entries.where((e) => e.value != null).toList();
    if (query != null && query.isNotEmpty) {
      final queryString = query
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      return Uri.parse('$fullUrl?$queryString');
    }

    return Uri.parse(fullUrl);
  }

  /// JSON-encodes the body; `null` and empty maps encode to no body.
  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is Map && body.isEmpty) return null;
    return jsonEncode(body);
  }

  Future<http.Response> _request(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    await beforeRequest();

    final mergedHeaders = buildHeaders(headers);
    final methodName = method.name.toUpperCase();
    final uri = _buildUri(path, query);

    // Generate request ID for correlation
    final requestId = _log.generateRequestId();
    final stopwatch = Stopwatch()..start();

    // Log the request
    if (enableLogging) {
      _log.request(
        method: methodName,
        url: uri.toString(),
        requestId: requestId,
        headers: mergedHeaders,
        body: body,
        queryParams: query,
        source: logSource,
      );
    }

    http.Response response;

    try {
      switch (method) {
        case HttpMethods.get:
          response = await http.get(uri, headers: mergedHeaders);
        case HttpMethods.post:
          response = await http.post(
            uri,
            headers: mergedHeaders,
            body: _encodeBody(body),
          );
        case HttpMethods.put:
          response = await http.put(
            uri,
            headers: mergedHeaders,
            body: _encodeBody(body),
          );
        case HttpMethods.patch:
          response = await http.patch(
            uri,
            headers: mergedHeaders,
            body: _encodeBody(body),
          );
        case HttpMethods.delete:
          response = await http.delete(
            uri,
            headers: mergedHeaders,
            body: _encodeBody(body),
          );
        case HttpMethods.unknown:
          throw const DragonflyNetworkInvalidMethodException(
              "Unknown HTTP method!");
      }

      stopwatch.stop();

      await afterResponse(response);

      // Log the response
      if (enableLogging) {
        dynamic responseBody;
        try {
          responseBody = jsonDecode(response.body);
        } catch (_) {
          responseBody = response.body;
        }

        _log.response(
          statusCode: response.statusCode,
          durationMs: stopwatch.elapsedMilliseconds,
          requestId: requestId,
          url: uri.toString(),
          method: methodName,
          statusMessage: response.reasonPhrase,
          headers: response.headers,
          body: responseBody,
          source: logSource,
        );
      }

      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();

      // Log the error
      if (enableLogging) {
        _log.error(
          'Request failed: $methodName ${uri.toString()}',
          error: e,
          stackTrace: stackTrace,
          source: logSource,
          data: {
            'requestId': requestId,
            'durationMs': stopwatch.elapsedMilliseconds
          },
        );
      }

      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> requestList(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final http.Response response = await _request(
      method,
      path,
      query: query,
      body: body,
      headers: headers,
    );

    _validateResponse(response);

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, Object?>>();
    }
    throw FormatException(
        'Expected List response but got ${decoded.runtimeType}');
  }

  @override
  Future<Map<String, Object?>> requestObject(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final http.Response response = await _request(
      method,
      path,
      query: query,
      body: body,
      headers: headers,
    );

    _validateResponse(response);

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
    throw FormatException(
        'Expected Map response but got ${decoded.runtimeType}');
  }

  /// Legacy entry point: [params] maps to the query string for GET/DELETE and
  /// to the body otherwise; [options] contributes only its headers.
  @override
  Future<List<Map<String, Object?>>> callForList(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) {
    final isQuery = method == HttpMethods.get || method == HttpMethods.delete;
    return requestList(
      method,
      path,
      query: isQuery ? params : null,
      body: isQuery ? null : params,
      headers: options?.headers,
    );
  }

  /// Legacy entry point; see [callForList] for the parameter mapping.
  @override
  Future<Map<String, Object?>> callForObject(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) {
    final isQuery = method == HttpMethods.get || method == HttpMethods.delete;
    return requestObject(
      method,
      path,
      query: isQuery ? params : null,
      body: isQuery ? null : params,
      headers: options?.headers,
    );
  }

  /// Validate HTTP response status code
  void _validateResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw DragonflyHttpException(
        'HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
        response.statusCode,
        response.body,
      );
    }
  }
}
