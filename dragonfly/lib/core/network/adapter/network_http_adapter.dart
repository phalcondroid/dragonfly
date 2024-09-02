import 'dart:convert';

import 'package:dragonfly/core/builder/types/enums/http_annotations.dart';
import 'package:dragonfly_annotations/enums/network_adapter.dart';
import 'package:http/http.dart' as http;

class NetworkHttpAdapter {
  Future<T> call<T>(NetworkAdapter adapter, String path, dynamic params,
      HttpAnnotations? networkMethod) async {
    http.Response response =
        await http.post(Uri.http(path), body: params.toJson());
    return jsonDecode(response.body) as T;
  }

  Future<List<T>> call<T>(NetworkAdapter adapter, String path, dynamic params,
      HttpAnnotations? networkMethod) async {
    http.Response response =
        await http.post(Uri.http(path), body: params.toJson());
    return jsonDecode(response.body) as List<T>;
  }
}
