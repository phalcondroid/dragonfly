// ---------------------------------------------------------------------------
// Extended config tests — initConfig on container, WebSocket adapter config
// with custom connectionName, adapters list with both HTTP + WS, validation
// messages on DragonflyConfig, interceptor variants.
// ---------------------------------------------------------------------------

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

  // ── DragonflyHttpAdapterConfig.initConfig ─────────────────────────────

  group('DragonflyHttpAdapterConfig.initConfig', () {
    test('registers adapter in a fresh container', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );

      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: defaultHttpNetwork,
        ),
        isTrue,
      );
    });

    test('registers authenticated adapter', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );

      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: 'defaultHttpNetwork:authenticated',
        ),
        isTrue,
      );
    });

    test('registers DragonflyNetworkHttpAdapter as concrete type', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );

      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I
            .isRegistered<DragonflyNetworkHttpAdapter>(
              instanceName: defaultHttpNetwork,
            ),
        isTrue,
      );
    });

    test('does not throw on valid config', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );

      expect(
        () => config.initConfig(DragonflyContainer.I),
        returnsNormally,
      );
    });

    test('is idempotent — does not re-register', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );

      config.initConfig(DragonflyContainer.I);
      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: defaultHttpNetwork,
        ),
        isTrue,
      );
    });

    test('registers with custom connectionName', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://custom.example.com'),
        connectionName: 'customHttp',
      );

      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: 'customHttp',
        ),
        isTrue,
      );
      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: 'customHttp:authenticated',
        ),
        isTrue,
      );
    });

    test('uses connectTimeout from options', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(
          baseUrl: 'https://example.com',
          connectTimeout: Duration(seconds: 10),
        ),
      );

      expect(config.options.connectTimeout, const Duration(seconds: 10));
    });
  });

  // ── DragonflyHttpBaseOptions ───────────────────────────────────────────

  group('DragonflyHttpBaseOptions', () {
    test('receiveTimeout can be customized', () {
      const options = DragonflyHttpBaseOptions(
        baseUrl: 'https://example.com',
        receiveTimeout: Duration(seconds: 10),
      );

      expect(options.receiveTimeout, const Duration(seconds: 10));
    });

    test('connectTimeout defaults to 5 seconds', () {
      const options = DragonflyHttpBaseOptions();

      expect(options.connectTimeout, const Duration(seconds: 5));
    });

    test('receiveTimeout defaults to 3 seconds', () {
      const options = DragonflyHttpBaseOptions();

      expect(options.receiveTimeout, const Duration(seconds: 3));
    });

    test('all fields can be set independently', () {
      const options = DragonflyHttpBaseOptions(
        baseUrl: 'https://api.dev/v2',
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 25),
      );

      expect(options.baseUrl, 'https://api.dev/v2');
      expect(options.connectTimeout, const Duration(seconds: 15));
      expect(options.receiveTimeout, const Duration(seconds: 25));
    });
  });

  // ── DragonflyWebSocketAdapterConfig.initConfig ────────────────────────

  group('DragonflyWebSocketAdapterConfig.initConfig', () {
    test('registers adapter in a fresh container', () {
      const config = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );

      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: defaultRealtimeNetwork,
        ),
        isTrue,
      );
    });

    test('registers DragonflyWebSocketAdapter as concrete type', () {
      const config = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );

      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I
            .isRegistered<DragonflyWebSocketAdapter>(
              instanceName: defaultRealtimeNetwork,
            ),
        isTrue,
      );
    });

    test('does not throw on valid config', () {
      const config = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );

      expect(
        () => config.initConfig(DragonflyContainer.I),
        returnsNormally,
      );
    });

    test('is idempotent — does not re-register', () {
      const config = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );

      config.initConfig(DragonflyContainer.I);
      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: defaultRealtimeNetwork,
        ),
        isTrue,
      );
    });

    test('registers with custom connectionName', () {
      const config = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://custom.example.com/ws'),
        connectionName: 'events',
        enableLogging: false,
      );

      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: 'events',
        ),
        isTrue,
      );
      expect(
        DragonflyContainer.I
            .isRegistered<DragonflyWebSocketAdapter>(
              instanceName: 'events',
            ),
        isTrue,
      );
    });

    test('constructor stores custom connectionName', () {
      const config = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        connectionName: 'myRealtime',
      );

      expect(config.connectionName, 'myRealtime');
    });
  });

  // ── DragonflyConfig: adapters with both HTTP and WebSocket ─────────────

  group('DragonflyConfig with both adapter types', () {
    test('adapters list can contain HTTP and WebSocket configs', () {
      const httpConfig = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(),
      );
      const wsConfig = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );

      const config = DragonflyConfig(
        adapters: [httpConfig, wsConfig],
      );

      expect(config.adapters, hasLength(2));
      expect(config.adapters[0], isA<DragonflyHttpAdapterConfig>());
      expect(config.adapters[1], isA<DragonflyWebSocketAdapterConfig>());
    });

    test('initConfig is called for each adapter when iterated', () {
      const httpConfig = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
      );
      const wsConfig = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );

      for (final adapter in [httpConfig, wsConfig]) {
        adapter.initConfig(DragonflyContainer.I);
      }

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: defaultHttpNetwork,
        ),
        isTrue,
      );
      expect(
        DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: defaultRealtimeNetwork,
        ),
        isTrue,
      );
    });
  });

  // ── DragonflyConfig: validationMessages ────────────────────────────────

  group('DragonflyConfig validationMessages', () {
    test('validationMessages can be set on DragonflyConfig', () {
      const messages = DragonflyValidationMessages();
      const config = DragonflyConfig(validationMessages: messages);

      expect(config.validationMessages, same(messages));
    });

    test('validationMessages defaults to null', () {
      const config = DragonflyConfig();

      expect(config.validationMessages, isNull);
    });

    test('validationMessages can be a subclass', () {
      const messages = _CustomMessages();
      const config = DragonflyConfig(validationMessages: messages);

      expect(config.validationMessages, isA<_CustomMessages>());
      expect(
        config.validationMessages?.required,
        'Obligatorio',
      );
    });
  });

  // ── DragonflyConfig: mix of new and deprecated fields ──────────────────

  group('DragonflyConfig deprecated + new fields', () {
    test('can set both adapters and deprecated instanceConfigs', () {
      const httpConfig = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(),
      );
      const deprecated = DragonflyInstanceConfig(
        options: DragonflyHttpBaseOptions(),
      );

      const config = DragonflyConfig(
        adapters: [httpConfig],
        instanceConfigs: [deprecated],
      );

      expect(config.adapters, hasLength(1));
      expect(config.instanceConfigs, hasLength(1));
    });

    test('can set both adapters and deprecated realtimeConfigs', () {
      const wsConfig = DragonflyWebSocketAdapterConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );
      const deprecated = DragonflyRealtimeInstanceConfig(
        config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
        enableLogging: false,
      );

      const config = DragonflyConfig(
        adapters: [wsConfig],
        realtimeConfigs: [deprecated],
      );

      expect(config.adapters, hasLength(1));
      expect(config.realtimeConfigs, hasLength(1));
    });
  });

  // ── DragonflyInterceptor ───────────────────────────────────────────────

  group('DragonflyInterceptor', () {
    test('all fields can be null', () {
      const interceptor = DragonflyInterceptor();

      expect(interceptor.before, isNull);
      expect(interceptor.after, isNull);
      expect(interceptor.catchError, isNull);
    });

    test('before callback can be set', () {
      Object beforeCallback(Object options, Object handler) => options;
      final interceptor = DragonflyInterceptor(before: beforeCallback);

      expect(interceptor.before, isNotNull);
    });

    test('after callback can be set', () {
      Object afterCallback(Object response, Object handler) => response;
      final interceptor = DragonflyInterceptor(after: afterCallback);

      expect(interceptor.after, isNotNull);
    });

    test('catchError callback can be set', () {
      void errorCallback(dynamic e, dynamic handler) {}
      final interceptor = DragonflyInterceptor(catchError: errorCallback);

      expect(interceptor.catchError, isNotNull);
    });
  });

  // ── DragonflyAdapterConfig abstract class ──────────────────────────────

  group('DragonflyAdapterConfig', () {
    test('custom subclass can override initConfig', () {
      final config = _CustomAdapterConfig();
      config.initConfig(DragonflyContainer.I);

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: 'customAdapter',
        ),
        isTrue,
      );
    });
  });

  // ── DragonflyConfig with injector ──────────────────────────────────────

  group('DragonflyConfig injector', () {
    test('injector can be set', () {
      Future<void> fn(DragonflyContainer c) async {}
      final injector = DragonflyInjector(inject: fn);
      final config = DragonflyConfig(injector: injector);

      expect(config.injector, isNotNull);
      expect(config.injector?.inject, isNotNull);
    });

    test('injector defaults to null', () {
      const config = DragonflyConfig();

      expect(config.injector, isNull);
    });
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _CustomMessages extends DragonflyValidationMessages {
  const _CustomMessages();

  @override
  String get required => 'Obligatorio';
}

class _CustomAdapterConfig extends DragonflyAdapterConfig {
  @override
  void initConfig(DragonflyContainer container) {
    container.registerSingleton<DragonflyBaseNetworkAdapter>(
      const DragonflyNetworkHttpAdapter(
        config: DragonflyNetworkConfig(
          baseUrl: 'https://custom.example.com',
        ),
      ),
      instanceName: 'customAdapter',
    );
  }
}
