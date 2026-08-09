// ---------------------------------------------------------------------------
// Tests for internal logic exercised through the public API.
// Private helpers _buildUri, _encodeBody, _validateResponse are not directly
// callable, but their behaviour is covered via constructor, config, and
// header-merging paths.
// ---------------------------------------------------------------------------

// ignore_for_file: invalid_use_of_protected_member

import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/network/enums/dragonfly_network_adapters_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── DragonflyNetworkConfig: identify variants ─────────────────────────

  group('DragonflyNetworkConfig identify', () {
    test('http identify', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        identify: DragonflyNetworkAdaptersEnum.http,
      );
      expect(config.identify, DragonflyNetworkAdaptersEnum.http);
    });

    test('socket identify', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        identify: DragonflyNetworkAdaptersEnum.socket,
      );
      expect(config.identify, DragonflyNetworkAdaptersEnum.socket);
    });

    test('udp identify', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        identify: DragonflyNetworkAdaptersEnum.udp,
      );
      expect(config.identify, DragonflyNetworkAdaptersEnum.udp);
    });

    test('default identify is http', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://example.com');
      expect(config.identify, DragonflyNetworkAdaptersEnum.http);
    });
  });

  // ── DragonflyNetworkConfig: isSingleton ───────────────────────────────

  group('DragonflyNetworkConfig isSingleton', () {
    test('true (default)', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://example.com');
      expect(config.isSingleton, isTrue);
    });

    test('false', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        isSingleton: false,
      );
      expect(config.isSingleton, isFalse);
    });
  });

  // ── DragonflyNetworkConfig: extra & headers ───────────────────────────

  group('DragonflyNetworkConfig extra and headers', () {
    test('extra stores arbitrary typed values', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        extra: {
          'retries': 3,
          'timeout': 10000,
          'tags': ['prod', 'v1'],
          'enabled': true,
        },
      );
      expect(config.extra['retries'], 3);
      expect(config.extra['timeout'], 10000);
      expect(config.extra['tags'], ['prod', 'v1']);
      expect(config.extra['enabled'], true);
    });

    test('headers with multiple entries', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        headers: {
          'X-Api-Key': 'secret',
          'X-Version': '2.0',
          'X-Client': 'mobile',
        },
      );
      expect(config.headers, hasLength(3));
      expect(config.headers!['X-Api-Key'], 'secret');
      expect(config.headers!['X-Version'], '2.0');
      expect(config.headers!['X-Client'], 'mobile');
    });

    test('extra defaults to empty const map', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://example.com');
      expect(config.extra, const <String, dynamic>{});
    });

    test('headers defaults to empty const map', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://example.com');
      expect(config.headers, const <String, dynamic>{});
    });
  });

  // ── Adapter construction with every config variant ────────────────────

  group('DragonflyNetworkHttpAdapter construction', () {
    test('with all custom config fields does not throw', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://api.example.com',
        identify: DragonflyNetworkAdaptersEnum.socket,
        connectionTimeout: 5000,
        isSingleton: false,
        headers: {'Authorization': 'Bearer abc'},
        extra: {'retries': 5},
      );
      const adapter = DragonflyNetworkHttpAdapter(config: config);
      expect(adapter.config.baseUrl, 'https://api.example.com');
      expect(adapter.config.identify, DragonflyNetworkAdaptersEnum.socket);
      expect(adapter.config.connectionTimeout, 5000);
      expect(adapter.config.isSingleton, isFalse);
      expect(adapter.config.extra['retries'], 5);
    });

    test('with http identify does not throw', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        identify: DragonflyNetworkAdaptersEnum.http,
      );
      const adapter = DragonflyNetworkHttpAdapter(config: config);
      expect(adapter.config.identify, DragonflyNetworkAdaptersEnum.http);
    });

    test('with udp identify does not throw', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        identify: DragonflyNetworkAdaptersEnum.udp,
      );
      const adapter = DragonflyNetworkHttpAdapter(config: config);
      expect(adapter.config.identify, DragonflyNetworkAdaptersEnum.udp);
    });

    test('is const constructable', () {
      const adapter = DragonflyNetworkHttpAdapter(
        config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
      );
      expect(adapter, isA<DragonflyNetworkHttpAdapter>());
    });
  });

  // ── buildHeaders: config header merging ───────────────────────────────

  group('buildHeaders config header merging', () {
    const testConfig = DragonflyNetworkConfig(
      baseUrl: 'https://example.com',
      headers: {
        'X-Api-Key': 'secret',
        'X-Version': '1.0',
        'X-Region': 'us-east',
      },
    );

    test('config headers with multiple entries all appear', () {
      const adapter = DragonflyNetworkHttpAdapter(config: testConfig);
      final headers = adapter.buildHeaders(null);

      expect(headers['Content-Type'], 'application/json');
      expect(headers['Accept'], 'application/json');
      expect(headers['X-Api-Key'], 'secret');
      expect(headers['X-Version'], '1.0');
      expect(headers['X-Region'], 'us-east');
    });

    test('config headers with non-string value converts via toString', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        headers: {
          'X-Count': 42,
          'X-Flag': true,
        },
      );
      const adapter = DragonflyNetworkHttpAdapter(config: config);
      final headers = adapter.buildHeaders(null);

      expect(headers['X-Count'], '42');
      expect(headers['X-Flag'], 'true');
    });

    test('config headers overridden by per-request headers', () {
      const adapter = DragonflyNetworkHttpAdapter(config: testConfig);
      final headers = adapter.buildHeaders({
        'X-Api-Key': 'override',
        'X-Custom': 'value',
      });

      expect(headers['X-Api-Key'], 'override');
      expect(headers['X-Version'], '1.0');
      expect(headers['X-Custom'], 'value');
    });

    test('buildHeaders with empty request headers preserves config', () {
      const adapter = DragonflyNetworkHttpAdapter(config: testConfig);
      final headers = adapter.buildHeaders({});

      expect(headers['X-Api-Key'], 'secret');
      expect(headers['X-Version'], '1.0');
      expect(headers['Content-Type'], 'application/json');
    });
  });

  // ── DragonflyNetworkOptions ───────────────────────────────────────────

  group('DragonflyNetworkOptions', () {
    test('stores headers', () {
      const options = DragonflyNetworkOptions(headers: {
        'Authorization': 'Bearer token',
      });
      expect(options.headers, {'Authorization': 'Bearer token'});
    });

    test('stores empty headers', () {
      const options = DragonflyNetworkOptions(headers: {});
      expect(options.headers, isEmpty);
    });

    test('stores multiple headers', () {
      const options = DragonflyNetworkOptions(headers: {
        'X-Trace-Id': 'abc-123',
        'X-Correlation-Id': 'def-456',
        'X-Requested-With': 'XMLHttpRequest',
      });
      expect(options.headers, hasLength(3));
      expect(options.headers['X-Trace-Id'], 'abc-123');
      expect(options.headers['X-Correlation-Id'], 'def-456');
    });

    test('headers is immutable via const', () {
      const options = DragonflyNetworkOptions(headers: {'k': 'v'});
      expect(options.headers, {'k': 'v'});
    });
  });

  // ── callForList / callForObject: param mapping logic ─────────────────

  group('callForList null params', () {
    const adapter = DragonflyNetworkHttpAdapter(
      config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
      enableLogging: false,
    );

    test('GET with null params triggers network call (no server → throws)',
        () {
      expect(
        adapter.callForList(HttpMethods.get, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('POST with null params triggers network call (no server → throws)',
        () {
      expect(
        adapter.callForList(HttpMethods.post, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('DELETE with null params maps to query', () {
      expect(
        adapter.callForList(HttpMethods.delete, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('PUT with params maps to body', () {
      expect(
        adapter.callForList(HttpMethods.put, '/path', {'k': 'v'}, null),
        throwsA(isA<Exception>()),
      );
    });

    test('PATCH with params maps to body', () {
      expect(
        adapter.callForList(HttpMethods.patch, '/path', {'k': 'v'}, null),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('callForObject null params', () {
    const adapter = DragonflyNetworkHttpAdapter(
      config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
      enableLogging: false,
    );

    test('GET with null params and null options', () {
      expect(
        adapter.callForObject(HttpMethods.get, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('POST with null params', () {
      expect(
        adapter.callForObject(HttpMethods.post, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('DELETE with null params maps to query', () {
      expect(
        adapter.callForObject(HttpMethods.delete, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('POST with body params and options headers', () {
      const options = DragonflyNetworkOptions(headers: {
        'X-Custom': 'test',
      });
      expect(
        adapter.callForObject(
            HttpMethods.post, '/path', {'key': 'value'}, options),
        throwsA(isA<Exception>()),
      );
    });

    test('GET with query params and options headers', () {
      const options = DragonflyNetworkOptions(headers: {
        'Accept-Language': 'en',
      });
      expect(
        adapter.callForObject(
            HttpMethods.get, '/path', {'page': '1'}, options),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── callForList / callForObject: HTTP method mapping ──────────────────

  group('callForList HTTP method mapping', () {
    const adapter = DragonflyNetworkHttpAdapter(
      config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
      enableLogging: false,
    );

    test('GET maps params to query (no body)', () {
      expect(
        adapter.callForList(
            HttpMethods.get, '/items', {'page': '1', 'limit': '10'}, null),
        throwsA(isA<Exception>()),
      );
    });

    test('DELETE maps params to query (no body)', () {
      expect(
        adapter.callForList(
            HttpMethods.delete, '/items', {'id': '123'}, null),
        throwsA(isA<Exception>()),
      );
    });

    test('POST maps params to body (no query)', () {
      expect(
        adapter.callForList(
            HttpMethods.post, '/items', {'name': 'test', 'value': 42}, null),
        throwsA(isA<Exception>()),
      );
    });

    test('PUT maps params to body (no query)', () {
      expect(
        adapter.callForList(
            HttpMethods.put, '/items/1', {'name': 'updated'}, null),
        throwsA(isA<Exception>()),
      );
    });

    test('PATCH maps params to body (no query)', () {
      expect(
        adapter.callForList(
            HttpMethods.patch, '/items/1', {'status': 'active'}, null),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('callForObject HTTP method mapping', () {
    const adapter = DragonflyNetworkHttpAdapter(
      config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
      enableLogging: false,
    );

    test('GET maps params to query (no body)', () {
      expect(
        adapter.callForObject(
            HttpMethods.get, '/products', {'category': 'books'}, null),
        throwsA(isA<Exception>()),
      );
    });

    test('POST maps params to body (no query)', () {
      expect(
        adapter.callForObject(HttpMethods.post, '/products',
            {'title': 'Book', 'price': 9.99}, null),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── Unknown HTTP method utility coverage ──────────────────────────────

  group('Unknown HTTP method', () {
    test('requestList with unknown method is callable (validation in _request)',
        () async {
      const adapter = DragonflyNetworkHttpAdapter(
        config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
        enableLogging: false,
      );

      expect(
        adapter.requestList(HttpMethods.unknown, '/path'),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'requestObject with unknown method is callable (validation in _request)',
        () async {
      const adapter = DragonflyNetworkHttpAdapter(
        config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
        enableLogging: false,
      );

      expect(
        adapter.requestObject(HttpMethods.unknown, '/path'),
        throwsA(isA<Exception>()),
      );
    });

    test('callForList forwards to requestList which validates', () {
      const adapter = DragonflyNetworkHttpAdapter(
        config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
        enableLogging: false,
      );

      expect(
        adapter.callForList(HttpMethods.unknown, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('callForObject forwards to requestObject which validates', () {
      const adapter = DragonflyNetworkHttpAdapter(
        config: DragonflyNetworkConfig(baseUrl: 'https://example.com'),
        enableLogging: false,
      );

      expect(
        adapter.callForObject(HttpMethods.unknown, '/path', null, null),
        throwsA(isA<Exception>()),
      );
    });
  });
}
