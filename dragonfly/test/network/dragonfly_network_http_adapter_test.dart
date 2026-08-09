import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _config = DragonflyNetworkConfig(baseUrl: 'https://example.com');

void main() {
  group('DragonflyNetworkHttpAdapter', () {
    test('constructor stores config', () {
      const adapter = DragonflyNetworkHttpAdapter(config: _config);

      expect(adapter.config, _config);
    });

    test('enableLogging defaults to true', () {
      const adapter = DragonflyNetworkHttpAdapter(config: _config);

      expect(adapter.enableLogging, isTrue);
    });

    test('enableLogging can be set to false', () {
      const adapter = DragonflyNetworkHttpAdapter(
        config: _config,
        enableLogging: false,
      );

      expect(adapter.enableLogging, isFalse);
    });

    test('logSource returns DragonflyNetworkHttpAdapter', () {
      const adapter = DragonflyNetworkHttpAdapter(config: _config);

      expect(adapter.logSource, 'DragonflyNetworkHttpAdapter');
    });

    test('type check — implements DragonflyBaseNetworkAdapter', () {
      const adapter = DragonflyNetworkHttpAdapter(config: _config);

      expect(adapter, isA<DragonflyBaseNetworkAdapter>());
    });

    group('buildHeaders', () {
      test('with null returns default JSON headers', () {
        const adapter = DragonflyNetworkHttpAdapter(config: _config);
        final headers = adapter.buildHeaders(null);

        expect(headers['Content-Type'], 'application/json');
        expect(headers['Accept'], 'application/json');
      });

      test('with custom headers merges them', () {
        const adapter = DragonflyNetworkHttpAdapter(config: _config);
        final headers = adapter.buildHeaders({'Authorization': 'Bearer token'});

        expect(headers['Content-Type'], 'application/json');
        expect(headers['Accept'], 'application/json');
        expect(headers['Authorization'], 'Bearer token');
      });

      test('custom headers override defaults', () {
        const adapter = DragonflyNetworkHttpAdapter(config: _config);
        final headers = adapter.buildHeaders({
          'Content-Type': 'text/xml',
        });

        expect(headers['Content-Type'], 'text/xml');
      });

      test('config headers are included', () {
        const adapter = DragonflyNetworkHttpAdapter(
          config: DragonflyNetworkConfig(
            baseUrl: 'https://example.com',
            headers: {'X-Api-Key': 'secret'},
          ),
        );
        final headers = adapter.buildHeaders(null);

        expect(headers['X-Api-Key'], 'secret');
      });

      test('per-request headers override config headers', () {
        const adapter = DragonflyNetworkHttpAdapter(
          config: DragonflyNetworkConfig(
            baseUrl: 'https://example.com',
            headers: {'X-Api-Key': 'secret', 'X-Version': '1'},
          ),
        );
        final headers = adapter.buildHeaders({
          'X-Api-Key': 'override',
        });

        expect(headers['X-Api-Key'], 'override');
        expect(headers['X-Version'], '1');
      });
    });

    group('lifecycle hooks', () {
      test('connect() does not throw', () async {
        const adapter = DragonflyNetworkHttpAdapter(config: _config);

        await adapter.connect();
      });

      test('disconnect() does not throw', () async {
        const adapter = DragonflyNetworkHttpAdapter(config: _config);

        await adapter.disconnect();
      });

      test('beforeRequest() does not throw', () async {
        const adapter = DragonflyNetworkHttpAdapter(config: _config);

        await adapter.beforeRequest();
      });

      test('afterResponse() does not throw', () async {
        const adapter = DragonflyNetworkHttpAdapter(config: _config);

        await adapter.afterResponse(http.Response('{}', 200));
      });
    });
  });
}
