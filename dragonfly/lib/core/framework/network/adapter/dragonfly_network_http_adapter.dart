import 'dart:convert';
import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly/core/framework/config/dragonfly_network_config.dart';
import 'package:dragonfly/core/framework/network/adapter/dragonfly_base_network_adapter.dart';
import 'package:dragonfly/core/framework/network/adapter/dragonfly_network_options.dart';
import 'package:dragonfly/core/framework/network/exceptions/dragonfly_network_invalid_method_exception.dart';
import 'package:http/http.dart' as http;

class DragonflyNetworkHttpAdapter implements DragonflyBaseNetworkAdapter {
  final DragonflyNetworkConfig config;

  const DragonflyNetworkHttpAdapter({required this.config});

  Future<http.Response> _callHttpMethod(HttpAnnotations method, String path,
      Map<String, dynamic>? params, DragonflyNetworkOptions? options) async {
    final String finalUrl = "${config.baseUrl}/$path";
    if (method == HttpAnnotations.get) {
      return await http.get(Uri.http(finalUrl));
    }
    if (method == HttpAnnotations.post) {
      return await http.post(Uri.http(finalUrl));
    }
    if (method == HttpAnnotations.patch) {
      return await http.patch(Uri.http(finalUrl));
    }
    if (method == HttpAnnotations.put) {
      return await http.put(Uri.http(finalUrl));
    }
    if (method == HttpAnnotations.delete) {
      return await http.delete(Uri.http(finalUrl));
    }
    throw const DragonflyNetworkInvalidMethodException(
        "Http method was not selected!");
  }

  @override
  Future<List<Map<String, Object?>>> callForList(
      HttpAnnotations method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options) async {
    http.Response response =
        await _callHttpMethod(method, path, params, options);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, Object?>> callForObject(
      HttpAnnotations method,
      String path,
      Map<String, dynamic>? params,
      DragonflyNetworkOptions? options) async {
    http.Response response =
        await _callHttpMethod(method, path, params, options);
    return jsonDecode(response.body);
  }
}
