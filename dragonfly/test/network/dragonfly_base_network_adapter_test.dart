import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAdapter implements DragonflyBaseNetworkAdapter {
  @override
  Future<List<Map<String, Object?>>> requestList(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    return [
      {'id': 1, 'name': 'test'}
    ];
  }

  @override
  Future<Map<String, Object?>> requestObject(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    return {'id': 1, 'name': 'test'};
  }

  @override
  Future<List<Map<String, Object?>>> callForList(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) async {
    return [
      {'id': 2, 'name': 'list'}
    ];
  }

  @override
  Future<Map<String, Object?>> callForObject(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) async {
    return {'id': 2, 'name': 'object'};
  }

  @override
  Future<void> beforeRequest() async {}

  @override
  Future<void> afterResponse(covariant dynamic response) async {}

  @override
  Map<String, String> buildHeaders(Map<String, String>? headers) =>
      headers ?? {};

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}

void main() {
  late _TestAdapter adapter;

  setUp(() {
    adapter = _TestAdapter();
  });

  group('DragonflyBaseNetworkAdapter', () {
    test('type check — implements DragonflyBaseNetworkAdapter', () {
      expect(adapter, isA<DragonflyBaseNetworkAdapter>());
    });

    test('requestObject() works', () async {
      final result = await adapter.requestObject(HttpMethods.get, '/test');

      expect(result['id'], 1);
      expect(result['name'], 'test');
    });

    test('requestList() works', () async {
      final result = await adapter.requestList(HttpMethods.get, '/test');

      expect(result, hasLength(1));
      expect(result.first['id'], 1);
      expect(result.first['name'], 'test');
    });

    test('callForList() works', () async {
      final result =
          await adapter.callForList(HttpMethods.get, '/test', null, null);

      expect(result, hasLength(1));
      expect(result.first['id'], 2);
      expect(result.first['name'], 'list');
    });

    test('callForObject() works', () async {
      final result =
          await adapter.callForObject(HttpMethods.get, '/test', null, null);

      expect(result['id'], 2);
      expect(result['name'], 'object');
    });

    test('beforeRequest() default is no-op', () async {
      await adapter.beforeRequest();
    });

    test('afterResponse() default is no-op', () async {
      await adapter.afterResponse(null);
    });

    test('buildHeaders() default returns empty map', () {
      final headers = adapter.buildHeaders(null);
      expect(headers, isEmpty);
    });

    test('buildHeaders() with headers returns them', () {
      final headers = adapter.buildHeaders({'X-Custom': 'value'});
      expect(headers, {'X-Custom': 'value'});
    });

    test('connect() default is no-op', () async {
      await adapter.connect();
    });

    test('disconnect() default is no-op', () async {
      await adapter.disconnect();
    });
  });
}
