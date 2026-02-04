import 'dart:convert';
import 'package:dragonfly/framework/config/dragonfly_network_config.dart';
import 'package:dragonfly/framework/logging/dragonfly_log_manager.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_base_network_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart';
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

  /// Build the final URL with query parameters for GET requests
  Uri _buildUri(String path, Map<String, dynamic>? queryParams) {
    final String baseUrl = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;

    final String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final String fullUrl = "$baseUrl/$cleanPath";

    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      return Uri.parse('$fullUrl?$queryString');
    }

    return Uri.parse(fullUrl);
  }

  /// Merge headers from config and options
  Map<String, String> _buildHeaders(DragonflyNetworkOptions? options) {
    final Map<String, String> headers = {};

    // Add default content-type
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';

    // Add headers from config
    if (config.headers != null) {
      config.headers!.forEach((key, value) {
        headers[key] = value.toString();
      });
    }

    // Add/override headers from options
    if (options != null) {
      headers.addAll(options.headers);
    }

    return headers;
  }

  /// Encode body for POST, PUT, PATCH requests
  String? _encodeBody(Map<String, dynamic>? body) {
    if (body == null || body.isEmpty) return null;
    return jsonEncode(body);
  }

  Future<http.Response> _callHttpMethod(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) async {
    final headers = _buildHeaders(options);
    final methodName = method.name.toUpperCase();
    final uri = method == HttpMethods.get || method == HttpMethods.delete
        ? _buildUri(path, params)
        : _buildUri(path, null);

    // Generate request ID for correlation
    final requestId = _log.generateRequestId();
    final stopwatch = Stopwatch()..start();

    // Log the request
    if (enableLogging) {
      _log.request(
        method: methodName,
        url: uri.toString(),
        requestId: requestId,
        headers: headers,
        body: method != HttpMethods.get ? params : null,
        queryParams: method == HttpMethods.get ? params : null,
        source: 'DragonflyNetworkHttpAdapter',
      );
    }

    http.Response response;

    try {
      switch (method) {
        case HttpMethods.get:
          response = await http.get(uri, headers: headers);
          break;

        case HttpMethods.post:
          response = await http.post(
            uri,
            headers: headers,
            body: _encodeBody(params),
          );
          break;

        case HttpMethods.put:
          response = await http.put(
            uri,
            headers: headers,
            body: _encodeBody(params),
          );
          break;

        case HttpMethods.patch:
          response = await http.patch(
            uri,
            headers: headers,
            body: _encodeBody(params),
          );
          break;

        case HttpMethods.delete:
          response = await http.delete(
            uri,
            headers: headers,
            body: _encodeBody(params),
          );
          break;

        case HttpMethods.unknow:
          throw const DragonflyNetworkInvalidMethodException(
              "Unknown HTTP method!");
      }

      stopwatch.stop();

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
          source: 'DragonflyNetworkHttpAdapter',
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
          source: 'DragonflyNetworkHttpAdapter',
          data: {'requestId': requestId, 'durationMs': stopwatch.elapsedMilliseconds},
        );
      }

      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> callForList(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) async {
    final http.Response response =
        await _callHttpMethod(method, path, params, options);

    _validateResponse(response);

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, Object?>>();
    }
    throw FormatException(
        'Expected List response but got ${decoded.runtimeType}');
  }

  @override
  Future<Map<String, Object?>> callForObject(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) async {
    final http.Response response =
        await _callHttpMethod(method, path, params, options);

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

/// Custom HTTP exception with status code and body
class DragonflyHttpException implements Exception {
  final String message;
  final int statusCode;
  final String body;

  const DragonflyHttpException(this.message, this.statusCode, this.body);

  @override
  String toString() => 'DragonflyHttpException: $message';
}
