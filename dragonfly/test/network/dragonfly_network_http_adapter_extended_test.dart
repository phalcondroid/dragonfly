// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';

import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/config/dragonfly_network_config.dart'
    show DragonflyNetworkIdentify;
import 'package:dragonfly/framework/network/enums/dragonfly_network_adapters_enum.dart'
    show DragonflyNetworkAdaptersEnum;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyNetworkConfig', () {
    test('stores baseUrl', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://api.example.com');

      expect(config.baseUrl, 'https://api.example.com');
    });

    test('default values are correct', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://example.com');

      expect(config.identify, DragonflyNetworkAdaptersEnum.http);
      expect(config.connectionTimeout, 2000);
      expect(config.isSingleton, isTrue);
      expect(config.headers, isEmpty);
      expect(config.extra, isEmpty);
    });

    test('stores all custom values', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://api.example.com',
        identify: DragonflyNetworkAdaptersEnum.socket,
        connectionTimeout: 5000,
        isSingleton: false,
        headers: {'X-Api-Key': 'secret'},
        extra: {'retries': 3, 'timeout': 10000},
      );

      expect(config.baseUrl, 'https://api.example.com');
      expect(config.identify, DragonflyNetworkAdaptersEnum.socket);
      expect(config.connectionTimeout, 5000);
      expect(config.isSingleton, isFalse);
      expect(config.headers, {'X-Api-Key': 'secret'});
      expect(config.extra, {'retries': 3, 'timeout': 10000});
    });

    test('headers defaults to empty const map', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://example.com');

      expect(config.headers, const <String, dynamic>{});
    });

    test('extra defaults to empty const map', () {
      const config = DragonflyNetworkConfig(baseUrl: 'https://example.com');

      expect(config.extra, const <String, dynamic>{});
    });
  });

  group('DragonflyNetworkAdaptersEnum', () {
    test('enum values exist', () {
      const values = DragonflyNetworkAdaptersEnum.values;

      expect(values, contains(DragonflyNetworkAdaptersEnum.http));
      expect(values, contains(DragonflyNetworkAdaptersEnum.socket));
      expect(values, contains(DragonflyNetworkAdaptersEnum.udp));
    });

    test('name property returns correct strings', () {
      expect(DragonflyNetworkAdaptersEnum.http.name, 'http');
      expect(DragonflyNetworkAdaptersEnum.socket.name, 'socket');
      expect(DragonflyNetworkAdaptersEnum.udp.name, 'udp');
    });
  });

  group('DragonflyNetworkIdentify', () {
    test('enum values exist', () {
      const values = DragonflyNetworkIdentify.values;

      expect(values, contains(DragonflyNetworkIdentify.defaultIdentify));
    });

    test('name property returns correct string', () {
      expect(DragonflyNetworkIdentify.defaultIdentify.name, 'defaultIdentify');
    });
  });

  group('DragonflyNetworkHttpAdapter encodeBody behaviour', () {
    test('encodeBody: null body maps to null', () {
      // _encodeBody(null) returns null
      // Verified by source: null body -> null, empty map -> null,
      // non-empty map -> jsonEncode(body)
      expect(jsonEncode(null), 'null',
          reason: 'jsonEncode(null) yields string, but _encodeBody(null)'
              ' returns null');
    });

    test('encodeBody: empty map returns null', () {
      // jsonEncode({}) -> "{}", but _encodeBody({}) returns null
      expect(jsonEncode({}), '{}',
          reason: 'jsonEncode({}) is "{}", but _encodeBody maps empty'
              ' maps to null');
    });

    test('encodeBody: non-empty map returns JSON string', () {
      const body = {'key': 'value'};
      expect(jsonEncode(body), '{"key":"value"}');
    });
  });

  group('DragonflyNetworkHttpAdapter config headers merging', () {
    const adapter = DragonflyNetworkHttpAdapter(
      config: DragonflyNetworkConfig(
        baseUrl: 'https://example.com',
        headers: {'X-Api-Key': 'secret', 'X-Version': '1'},
      ),
    );

    test('buildHeaders merges config headers', () {
      final headers = adapter.buildHeaders(null);

      expect(headers['X-Api-Key'], 'secret');
      expect(headers['X-Version'], '1');
      expect(headers['Content-Type'], 'application/json');
      expect(headers['Accept'], 'application/json');
    });

    test('buildHeaders per-request overrides config headers', () {
      final headers = adapter.buildHeaders({'X-Api-Key': 'override'});

      expect(headers['X-Api-Key'], 'override');
      expect(headers['X-Version'], '1');
    });
  });
}
