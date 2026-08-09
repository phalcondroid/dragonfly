import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoOverrideAdapter extends DragonflyBaseNetworkAdapter {
  @override
  Future<List<Map<String, Object?>>> requestList(HttpMethods method, String path,
      {Map<String, dynamic>? query, Object? body, Map<String, String>? headers}) async {
    await beforeRequest();
    final h = buildHeaders(headers);
    await afterResponse('ok');
    return [];
  }

  @override
  Future<Map<String, Object?>> requestObject(HttpMethods method, String path,
      {Map<String, dynamic>? query, Object? body, Map<String, String>? headers}) async {
    return {};
  }

  @override
  Future<List<Map<String, Object?>>> callForList(HttpMethods method, String path,
      Map<String, dynamic>? params, DragonflyNetworkOptions? options) async {
    return [];
  }

  @override
  Future<Map<String, Object?>> callForObject(HttpMethods method, String path,
      Map<String, dynamic>? params, DragonflyNetworkOptions? options) async {
    return {};
  }
}

void main() {
  group('Base adapter default hooks', () {
    test('beforeRequest default is no-op', () async {
      final a = _MinAdapter();
      await a.beforeRequest();
    });

    test('buildHeaders with null returns empty map', () {
      final a = _MinAdapter();
      expect(a.buildHeaders(null), isEmpty);
    });

    test('buildHeaders with headers returns them', () {
      final a = _MinAdapter();
      expect(a.buildHeaders({'a': 'b'}), {'a': 'b'});
    });

    test('afterResponse default is no-op', () async {
      final a = _MinAdapter();
      await a.afterResponse(null);
    });

    test('connect default is no-op', () async {
      final a = _MinAdapter();
      await a.connect();
    });

    test('disconnect default is no-op', () async {
      final a = _MinAdapter();
      await a.disconnect();
    });

    test('calls hooks in requestList', () async {
      final a = _NoOverrideAdapter();
      await a.requestList(HttpMethods.get, '/');
    });
  });

  group('WebSocketAdapter edge cases', () {
    test('RealtimeState values exist', () {
      expect(DragonflyRealtimeState.disconnected, isA<DragonflyRealtimeState>());
      expect(DragonflyRealtimeState.connecting, isA<DragonflyRealtimeState>());
      expect(DragonflyRealtimeState.connected, isA<DragonflyRealtimeState>());
      expect(DragonflyRealtimeState.reconnecting, isA<DragonflyRealtimeState>());
      expect(DragonflyRealtimeState.closed, isA<DragonflyRealtimeState>());
    });
  });

  group('DragonflyContainerHelper', () {
    setUp(() => DragonflyContainer.I.reset());
    tearDown(() => DragonflyContainer.I.reset());

    test('call operator works', () {
      DragonflyContainer.I.registerSingleton<String>('hello');
      final h = DragonflyContainerHelper(DragonflyContainer.I);
      expect(h<String>(), 'hello');
    });

    test('factory param factoryFunc', () {
      DragonflyContainer.I.registerFactory<int>(() => 42);
      expect(DragonflyContainer.I.get<int>(), 42);
    });
  });
}

class _MinAdapter extends DragonflyBaseNetworkAdapter {
  @override
  Future<List<Map<String, Object?>>> requestList(HttpMethods method, String path,
      {Map<String, dynamic>? query, Object? body, Map<String, String>? headers}) async => [];
  @override
  Future<Map<String, Object?>> requestObject(HttpMethods method, String path,
      {Map<String, dynamic>? query, Object? body, Map<String, String>? headers}) async => {};
  @override
  Future<List<Map<String, Object?>>> callForList(HttpMethods method, String path,
      Map<String, dynamic>? params, DragonflyNetworkOptions? options) async => [];
  @override
  Future<Map<String, Object?>> callForObject(HttpMethods method, String path,
      Map<String, dynamic>? params, DragonflyNetworkOptions? options) async => {};
}
