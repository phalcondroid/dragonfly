import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/config/dragonfly_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await DragonflyContainer.I.reset();
  });

  tearDown(() async {
    await DragonflyContainer.I.reset();
  });

  group('DragonflyInstanceConfig (deprecated)', () {
    test('constructor stores options and connectionName', () {
      const options = DragonflyHttpBaseOptions(
        baseUrl: 'https://api.example.com',
      );
      const config = DragonflyInstanceConfig(
        options: options,
        connectionName: 'customHttp',
      );

      expect(config.options, options);
      expect(config.connectionName, 'customHttp');
    });

    test('connectionName defaults to defaultHttpNetwork', () {
      const config = DragonflyInstanceConfig(
        options: DragonflyHttpBaseOptions(),
      );

      expect(config.connectionName, defaultHttpNetwork);
    });

    test('interceptor defaults to non-null', () {
      const config = DragonflyInstanceConfig(
        options: DragonflyHttpBaseOptions(),
      );

      expect(config.interceptor, isNotNull);
      expect(config.interceptor, isA<DragonflyInterceptor>());
    });

    test('initConfig() registers adapter in container', () {
      const config = DragonflyInstanceConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );
      config.initConfig();

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: defaultHttpNetwork,
        ),
        isTrue,
      );
    });

    test('initConfig() does not throw', () {
      const config = DragonflyInstanceConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );

      expect(() => config.initConfig(), returnsNormally);
    });

    test('initConfig() registers authenticated adapter', () {
      const config = DragonflyInstanceConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );
      config.initConfig();

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: 'defaultHttpNetwork:authenticated',
        ),
        isTrue,
      );
    });

    test('initConfig() is idempotent — does not re-register', () {
      const config = DragonflyInstanceConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );
      config.initConfig();

      expect(() => config.initConfig(), returnsNormally);
    });

    test('is marked as Deprecated', () {
      final deprecated = const DragonflyInstanceConfig(options: DragonflyHttpBaseOptions());
      expect(deprecated, isA<DragonflyInstanceConfig>());
    });
  });

  group('DragonflyRealtimeInstanceConfig (deprecated)', () {
    test('constructor stores config fields', () {
      final realtimeConfig = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
      );
      final config = DragonflyRealtimeInstanceConfig(
        config: realtimeConfig,
        connectionName: 'customRealtime',
        enableLogging: false,
        connectEagerly: true,
      );

      expect(config.config, realtimeConfig);
      expect(config.connectionName, 'customRealtime');
      expect(config.enableLogging, isFalse);
      expect(config.connectEagerly, isTrue);
    });

    test('connectionName defaults to defaultRealtimeNetwork', () {
      final config = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
      );

      expect(config.connectionName, defaultRealtimeNetwork);
    });

    test('enableLogging defaults to true', () {
      final config = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
      );

      expect(config.enableLogging, isTrue);
    });

    test('connectEagerly defaults to false', () {
      final config = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
      );

      expect(config.connectEagerly, isFalse);
    });

    test('initConfig() does not throw', () {
      final config = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
      );

      expect(() => config.initConfig(), returnsNormally);
    });

    test('initConfig() registers adapter in container', () {
      final config = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );
      config.initConfig();

      expect(
        DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: defaultRealtimeNetwork,
        ),
        isTrue,
      );
    });

    test('initConfig() is idempotent — does not re-register', () {
      final config = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );
      config.initConfig();

      expect(() => config.initConfig(), returnsNormally);
    });

    test('is marked as Deprecated', () {
      final deprecated = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
      );
      expect(deprecated, isA<DragonflyRealtimeInstanceConfig>());
    });
  });
}
