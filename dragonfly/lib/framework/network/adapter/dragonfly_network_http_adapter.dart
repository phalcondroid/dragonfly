import 'dart:convert';
import 'package:dragonfly/framework/config/dragonfly_network_config.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_base_network_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart';
import 'package:dragonfly/framework/network/exceptions/dragonfly_network_invalid_method_exception.dart';
import 'package:dragonfly/framework/types/enums/http_methods.dart';
import 'package:http/http.dart' as http;

class DragonflyNetworkHttpAdapter implements DragonflyBaseNetworkAdapter {
  final DragonflyNetworkConfig config;

  const DragonflyNetworkHttpAdapter({required this.config});

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

    switch (method) {
      case HttpMethods.get:
        return await http.get(
          _buildUri(path, params),
          headers: headers,
        );

      case HttpMethods.post:
        return await http.post(
          _buildUri(path, null),
          headers: headers,
          body: _encodeBody(params),
        );

      case HttpMethods.put:
        return await http.put(
          _buildUri(path, null),
          headers: headers,
          body: _encodeBody(params),
        );

      case HttpMethods.patch:
        return await http.patch(
          _buildUri(path, null),
          headers: headers,
          body: _encodeBody(params),
        );

      case HttpMethods.delete:
        return await http.delete(
          _buildUri(path, params),
          headers: headers,
          body: _encodeBody(params),
        );

      case HttpMethods.unknow:
        throw const DragonflyNetworkInvalidMethodException(
            "Unknown HTTP method!");
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
