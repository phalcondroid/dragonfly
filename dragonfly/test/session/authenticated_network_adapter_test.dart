// ignore_for_file: inference_failure_on_function_invocation

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _StubAdapter implements DragonflyBaseNetworkAdapter {
  _StubAdapter({
    List<Map<String, Object?>>? listResponse,
    Map<String, Object?>? objectResponse,
  })  : _listResponse = listResponse ?? [],
        _objectResponse = objectResponse ?? {};

  final List<Map<String, Object?>> _listResponse;
  final Map<String, Object?> _objectResponse;
  bool beforeRequestCalled = false;
  bool afterResponseCalled = false;
  bool connectCalled = false;
  bool disconnectCalled = false;
  bool requestObjectCalled = false;
  bool requestListCalled = false;
  Map<String, String>? lastHeadersBuilt;

  @override
  Future<List<Map<String, Object?>>> callForList(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) async =>
      _listResponse;

  @override
  Future<Map<String, Object?>> callForObject(
    HttpMethods method,
    String path,
    Map<String, dynamic>? params,
    DragonflyNetworkOptions? options,
  ) async =>
      _objectResponse;

  @override
  Future<List<Map<String, Object?>>> requestList(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    requestListCalled = true;
    return _listResponse;
  }

  @override
  Future<Map<String, Object?>> requestObject(
    HttpMethods method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    requestObjectCalled = true;
    return _objectResponse;
  }

  @override
  Map<String, String> buildHeaders(Map<String, String>? headers) {
    lastHeadersBuilt = headers;
    return Map.from(headers ?? {});
  }

  @override
  Future<void> beforeRequest() async {
    beforeRequestCalled = true;
  }

  @override
  Future<void> afterResponse(dynamic response) async {
    afterResponseCalled = true;
  }

  @override
  Future<void> connect() async {
    connectCalled = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }
}

const _baseConfig = DragonflyNetworkConfig(baseUrl: 'https://example.com');

void main() {
  group('DragonflyAuthenticatedAdapter', () {
    setUp(() async {
      await DragonflySessionManager.instance.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    group('constructor', () {
      test('stores the inner adapter', () {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        expect(adapter.inner, same(inner));
      });

      test('type check — implements DragonflyBaseNetworkAdapter', () {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        expect(adapter, isA<DragonflyBaseNetworkAdapter>());
      });
    });

    group('buildHeaders', () {
      test('delegates to inner builder when not authenticated', () {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        final result = adapter.buildHeaders({'X-Custom': 'value'});

        expect(inner.beforeRequestCalled, isFalse);
        expect(result['X-Custom'], 'value');
      });

      test('adds auth header when session is authenticated', () async {
        await DragonflySessionManager.I.login(token: 'auth-token');

        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        final result = adapter.buildHeaders({'X-Custom': 'value'});

        expect(result['X-Custom'], 'value');
        expect(result['Authorization'], 'Bearer auth-token');
      });

      test('does not add auth header when session is unauthenticated', () {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        final result = adapter.buildHeaders(null);

        expect(result.containsKey('Authorization'), isFalse);
      });

      test('respects tokenTypeOverride', () async {
        await DragonflySessionManager.I.login(token: 'auth-token');

        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(
          inner: inner,
          tokenTypeOverride: 'JWT',
        );

        final result = adapter.buildHeaders(null);

        expect(result['Authorization'], 'JWT auth-token');
      });

      test('respects authHeaderOverride', () async {
        await DragonflySessionManager.I.login(token: 'auth-token');

        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(
          inner: inner,
          authHeaderOverride: 'X-Auth',
        );

        final result = adapter.buildHeaders(null);

        expect(result['X-Auth'], 'Bearer auth-token');
        expect(result.containsKey('Authorization'), isFalse);
      });
    });

    group('beforeRequest', () {
      test('calls inner.beforeRequest', () async {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.beforeRequest();

        expect(inner.beforeRequestCalled, isTrue);
      });

      test('refreshes token when session is expired and refreshTokenCallback is set',
          () async {
        await DragonflySessionManager.I.login(
          token: 'expired-token',
          expiresIn: const Duration(seconds: -1),
        );

        var refreshed = false;
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(
          inner: inner,
          refreshTokenCallback: () async {
            refreshed = true;
            return 'fresh-token';
          },
        );

        await adapter.beforeRequest();

        expect(refreshed, isTrue);
        expect(DragonflySessionManager.I.token, 'fresh-token');
      });

      test('does not refresh token when session is not expired', () async {
        await DragonflySessionManager.I.login(
          token: 'valid-token',
          expiresIn: const Duration(hours: 1),
        );

        var refreshed = false;
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(
          inner: inner,
          refreshTokenCallback: () async {
            refreshed = true;
            return 'should-not-be-called';
          },
        );

        await adapter.beforeRequest();

        expect(refreshed, isFalse);
        expect(DragonflySessionManager.I.token, 'valid-token');
      });
    });

    group('afterResponse', () {
      test('calls inner.afterResponse', () async {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.afterResponse('some response');

        expect(inner.afterResponseCalled, isTrue);
      });
    });

    group('connect / disconnect', () {
      test('connect delegates to inner', () async {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.connect();

        expect(inner.connectCalled, isTrue);
      });

      test('disconnect delegates to inner', () async {
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.disconnect();

        expect(inner.disconnectCalled, isTrue);
      });
    });

    group('requestObject', () {
      test('delegates to inner after calling hooks', () async {
        await DragonflySessionManager.I.login(token: 'request-token');

        final inner = _StubAdapter(objectResponse: {'key': 'value'});
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        final result = await adapter.requestObject(
          HttpMethods.get,
          '/test',
          headers: {'X-Custom': 'val'},
        );

        expect(inner.requestObjectCalled, isTrue);
        expect(result, {'key': 'value'});
      });

      test('passes built headers to inner request', () async {
        await DragonflySessionManager.I.login(token: 'request-token');

        final inner = _StubAdapter(objectResponse: {});
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.requestObject(
          HttpMethods.get,
          '/test',
          headers: {'X-Custom': 'val'},
        );

        expect(inner.requestObjectCalled, isTrue);
      });

      test('passes query and body to inner request', () async {
        await DragonflySessionManager.I.login(token: 'request-token');

        final inner = _StubAdapter(objectResponse: {});
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.requestObject(
          HttpMethods.post,
          '/test',
          query: {'page': '1'},
          body: {'name': 'value'},
        );

        expect(inner.requestObjectCalled, isTrue);
      });
    });

    group('requestList', () {
      test('delegates to inner after calling hooks', () async {
        await DragonflySessionManager.I.login(token: 'request-token');

        final inner = _StubAdapter(
            listResponse: [{'item': 1}]);
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        final result = await adapter.requestList(
          HttpMethods.get,
          '/items',
          headers: {'X-Custom': 'val'},
        );

        expect(inner.requestListCalled, isTrue);
        expect(result, [{'item': 1}]);
      });

      test('passes built headers to inner request', () async {
        await DragonflySessionManager.I.login(token: 'request-token');

        final inner = _StubAdapter(listResponse: []);
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.requestList(
          HttpMethods.get,
          '/items',
          headers: {'X-Custom': 'val'},
        );

        expect(inner.requestListCalled, isTrue);
      });
    });

    group('callForObject / callForList', () {
      test('callForObject delegates to inner', () async {
        final inner = _StubAdapter(objectResponse: {'data': 1});
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        final result = await adapter.callForObject(
          HttpMethods.get,
          '/path',
          {'param': 'value'},
          const DragonflyNetworkOptions(headers: {}),
        );

        expect(result, {'data': 1});
      });

      test('callForList delegates to inner', () async {
        final inner = _StubAdapter(
            listResponse: [{'item': 1}]);
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        final result = await adapter.callForList(
          HttpMethods.get,
          '/path',
          {'param': 'value'},
          const DragonflyNetworkOptions(headers: {}),
        );

        expect(result, [{'item': 1}]);
      });
    });

    group('handleUnauthorized', () {
      test('does not throw without onTokenExpired', () async {
        await DragonflySessionManager.I.login(token: 'token');

        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(inner: inner);

        await adapter.handleUnauthorized();

        expect(DragonflySessionManager.I.isAuthenticated, isFalse);
      });

      test('calls onTokenExpired callback when set', () async {
        await DragonflySessionManager.I.login(token: 'token');

        var expiredCalled = false;
        final inner = _StubAdapter();
        final adapter = DragonflyAuthenticatedAdapter(
          inner: inner,
          onTokenExpired: () async {
            expiredCalled = true;
          },
        );

        await adapter.handleUnauthorized();

        expect(expiredCalled, isTrue);
        expect(DragonflySessionManager.I.isAuthenticated, isTrue);
      });
    });
  });

  group('AuthenticatedNetworkAdapter (deprecated)', () {
    setUp(() async {
      await DragonflySessionManager.instance.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('constructor stores config', () {
      const adapter = AuthenticatedNetworkAdapter(config: _baseConfig);

      expect(adapter.config, _baseConfig);
    });

    test('logSource returns AuthenticatedNetworkAdapter', () {
      const adapter = AuthenticatedNetworkAdapter(config: _baseConfig);

      expect(adapter.logSource, 'AuthenticatedNetworkAdapter');
    });

    test('type check — is a DragonflyNetworkHttpAdapter', () {
      const adapter = AuthenticatedNetworkAdapter(config: _baseConfig);

      expect(adapter, isA<DragonflyNetworkHttpAdapter>());
    });

    test('buildHeaders adds auth header when session is authenticated',
        () async {
      await DragonflySessionManager.I.login(token: 'deprecated-token');

      const adapter = AuthenticatedNetworkAdapter(config: _baseConfig);

      final result = adapter.buildHeaders({'X-Custom': 'val'});

      expect(result['Authorization'], 'Bearer deprecated-token');
      expect(result['X-Custom'], 'val');
    });

    test('buildHeaders does not add auth when session is not authenticated',
        () {
      const adapter = AuthenticatedNetworkAdapter(config: _baseConfig);

      final result = adapter.buildHeaders(null);

      expect(result.containsKey('Authorization'), isFalse);
    });

    test('beforeRequest does not throw', () async {
      const adapter = AuthenticatedNetworkAdapter(config: _baseConfig);

      await expectLater(adapter.beforeRequest(), completes);
    });

    test('beforeRequest refreshes token when expired', () async {
      await DragonflySessionManager.I.login(
        token: 'expired',
        expiresIn: const Duration(seconds: -1),
      );

      const adapter = AuthenticatedNetworkAdapter(
        config: _baseConfig,
        refreshTokenCallback: _refreshTokenCallback,
      );

      await adapter.beforeRequest();

      expect(DragonflySessionManager.I.token, 'refreshed-via-deprecated');
    });

    test('afterResponse logs out on 401 without onTokenExpired', () async {
      await DragonflySessionManager.I.login(token: 'token');

      const adapter = AuthenticatedNetworkAdapter(config: _baseConfig);
      final response = http.Response('Unauthorized', 401);

      await adapter.afterResponse(response);

      expect(DragonflySessionManager.I.isAuthenticated, isFalse);
    });

    test('afterResponse calls onTokenExpired on 401', () async {
      await DragonflySessionManager.I.login(token: 'token');

      var expiredCalled = false;
      final adapter = AuthenticatedNetworkAdapter(
        config: _baseConfig,
        onTokenExpired: () async {
          expiredCalled = true;
        },
      );

      final response = http.Response('Unauthorized', 401);
      await adapter.afterResponse(response);

      expect(expiredCalled, isTrue);
    });

    test('afterResponse does nothing on non-401 status', () async {
      await DragonflySessionManager.I.login(token: 'token');

      var expiredCalled = false;
      final adapter = AuthenticatedNetworkAdapter(
        config: _baseConfig,
        onTokenExpired: () async {
          expiredCalled = true;
        },
      );

      final response = http.Response('OK', 200);
      await adapter.afterResponse(response);

      expect(expiredCalled, isFalse);
      expect(DragonflySessionManager.I.isAuthenticated, isTrue);
    });

    test('afterResponse with onTokenExpired logout callback preserves session',
        () async {
      await DragonflySessionManager.I.login(token: 'token');

      final adapter = AuthenticatedNetworkAdapter(
        config: _baseConfig,
        onTokenExpired: () async {},
      );

      final response = http.Response('Unauthorized', 401);
      await adapter.afterResponse(response);

      expect(DragonflySessionManager.I.isAuthenticated, isTrue);
    });
  });
}

Future<String?> _refreshTokenCallback() async {
  return 'refreshed-via-deprecated';
}
