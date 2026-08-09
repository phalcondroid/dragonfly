// ignore_for_file: strict_raw_type, inference_failure_on_function_invocation

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

class _CustomMessages extends DragonflyValidationMessages {
  const _CustomMessages();
  @override
  String get required => 'Pflichtfeld';
}

void main() {
  setUp(() async {
    await DragonflyContainer.I.reset();
  });

  tearDown(() async {
    await DragonflyContainer.I.reset();
  });

  // ── Constructor ─────────────────────────────────────────────────────

  group('DragonflyApp constructor', () {
    test('config is required and stored', () {
      const config = DragonflyConfig();
      final app = DragonflyApp(config: config);
      expect(app.config, same(config));
    });

    test('itemDbConfig can be set', () {
      const itemDb = DragonflyLocalStorageConfig(databaseName: 'test_db');
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        itemDbConfig: [itemDb],
      );
      expect(app.itemDbConfig, hasLength(1));
      expect(app.itemDbConfig!.first.databaseName, 'test_db');
    });

    test('itemDbConfig defaults to null', () {
      final app = DragonflyApp(config: const DragonflyConfig());
      expect(app.itemDbConfig, isNull);
    });

    test('all constructor params can be set', () {
      const itemDb = DragonflyLocalStorageConfig(databaseName: 'my_db');
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        itemDbConfig: [itemDb],
        showBanner: false,
        enableLogging: false,
        minLogLevel: DragonflyLogLevel.error,
      );

      expect(app.showBanner, isFalse);
      expect(app.enableLogging, isFalse);
      expect(app.minLogLevel, DragonflyLogLevel.error);
    });

    test('showBanner defaults to true', () {
      final app = DragonflyApp(config: const DragonflyConfig());
      expect(app.showBanner, isTrue);
    });

    test('enableLogging defaults to true', () {
      final app = DragonflyApp(config: const DragonflyConfig());
      expect(app.enableLogging, isTrue);
    });

    test('minLogLevel defaults to info', () {
      final app = DragonflyApp(config: const DragonflyConfig());
      expect(app.minLogLevel, DragonflyLogLevel.info);
    });
  });

  // ── Version ─────────────────────────────────────────────────────────

  group('version', () {
    test('returns a valid semver string', () {
      final version = DragonflyApp.version;
      expect(version, isNotEmpty);
      expect(version, contains('.'));
      final parts = version.split('.');
      expect(parts, hasLength(3));
      for (final part in parts) {
        expect(int.tryParse(part), isNotNull);
      }
    });
  });

  // ── init() ──────────────────────────────────────────────────────────

  group('init', () {
    test('init with showBanner false does not throw', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: false,
      );
      await expectLater(app.init(), completes);
    });

    test('init with enableLogging false does not throw', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: true,
        enableLogging: false,
      );
      await expectLater(app.init(), completes);
    });

    test('init with both showBanner and enableLogging false', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: false,
      );
      await expectLater(app.init(), completes);
    });

    test('multiple init calls are safe', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: false,
      );
      await app.init();
      await app.init();
    });

    test('init with minLogLevel sets min level on log manager', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: false,
        minLogLevel: DragonflyLogLevel.error,
      );
      await app.init();

      final log = DragonflyLogManager.instance;
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.setEnabled(true);
      log.setPrintToConsole(false);
      log.addListener(listener);

      log.info('should be filtered');
      log.debug('should be filtered');
      log.warning('should be filtered');
      expect(received, isEmpty);

      log.error('should pass', error: Exception('x'));
      expect(received, hasLength(1));

      log.removeListener(listener);
    });
  });

  // ── init() with adapters ────────────────────────────────────────────

  group('init with adapters', () {
    test('init with HTTP adapter config registers adapter', () async {
      const config = DragonflyConfig(
        adapters: [
          DragonflyHttpAdapterConfig(
            options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
          ),
        ],
      );
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: defaultHttpNetwork,
        ),
        isTrue,
      );
    });

    test('init with WebSocket adapter config registers adapter', () async {
      const config = DragonflyConfig(
        adapters: [
          DragonflyWebSocketAdapterConfig(
            config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
            enableLogging: false,
          ),
        ],
      );
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      expect(
        DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: defaultRealtimeNetwork,
        ),
        isTrue,
      );
    });

    test('init with both HTTP and WebSocket adapters', () async {
      const config = DragonflyConfig(
        adapters: [
          DragonflyHttpAdapterConfig(
            options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
          ),
          DragonflyWebSocketAdapterConfig(
            config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
            enableLogging: false,
          ),
        ],
      );
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

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

  // ── init() with validation messages ─────────────────────────────────

  group('init with validationMessages', () {
    test('validationMessages are set on Validators', () async {
      const messages = _CustomMessages();
      const config = DragonflyConfig(validationMessages: messages);
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      final validate = Validators.required<String>();
      expect(validate(null), 'Pflichtfeld');
    });

    test('null validationMessages does not throw', () async {
      const config = DragonflyConfig();
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await expectLater(app.init(), completes);
    });
  });

  // ── init() with showBanner ──────────────────────────────────────────

  group('init with showBanner', () {
    test('showBanner true prints banner when logging enabled', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: true,
        enableLogging: true,
      );
      final log = DragonflyLogManager.instance;
      log.setPrintToConsole(false);

      await expectLater(app.init(), completes);
    });

    test('showBanner false suppresses banner', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: true,
      );
      final log = DragonflyLogManager.instance;
      log.setPrintToConsole(false);

      await expectLater(app.init(), completes);
    });

    test('showBanner true but enableLogging false suppresses banner', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: true,
        enableLogging: false,
      );
      await expectLater(app.init(), completes);
    });
  });

  // ── init() with deprecated configs ──────────────────────────────────

  group('init with deprecated configs', () {
    test('init with deprecated instanceConfigs works', () async {
      final config = DragonflyConfig(
        instanceConfigs: const [
          DragonflyInstanceConfig(
            options: DragonflyHttpBaseOptions(baseUrl: 'https://example.com'),
          ),
        ],
      );
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      expect(
        DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: defaultHttpNetwork,
        ),
        isTrue,
      );
    });

    test('init with deprecated realtimeConfigs works', () async {
      final config = DragonflyConfig(
        realtimeConfigs: const [
          DragonflyRealtimeInstanceConfig(
            config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
            enableLogging: false,
          ),
        ],
      );
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      expect(
        DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: defaultRealtimeNetwork,
        ),
        isTrue,
      );
    });

    test('init with both new and deprecated configs coexists', () async {
      final config = DragonflyConfig(
        adapters: const [
          DragonflyHttpAdapterConfig(
            options: DragonflyHttpBaseOptions(baseUrl: 'https://a.example.com'),
          ),
        ],
        realtimeConfigs: const [
          DragonflyRealtimeInstanceConfig(
            config: DragonflyRealtimeConfig(url: 'wss://b.example.com/ws'),
            enableLogging: false,
          ),
        ],
      );
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

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

  // ── init() with custom injector ─────────────────────────────────────

  group('init with custom injector', () {
    test('injector callback is called during init', () async {
      var callbackCalled = false;
      final injector = DragonflyInjector(inject: (container) async {
        callbackCalled = true;
        container.registerSingleton<String>('injected_value', instanceName: 'custom');
      });

      final config = DragonflyConfig(injector: injector);
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      expect(callbackCalled, isTrue);
      expect(
        DragonflyContainer.I.get<String>(instanceName: 'custom'),
        'injected_value',
      );
    });

    test('injector can be null without error', () async {
      const config = DragonflyConfig();
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await expectLater(app.init(), completes);
    });
  });

  // ── init() with enableLogging ───────────────────────────────────────

  group('init with enableLogging', () {
    test('enableLogging true enables the log manager', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: true,
      );
      DragonflyLogManager.instance.setPrintToConsole(false);
      await app.init();

      final log = DragonflyLogManager.instance;
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.setEnabled(true);
      log.setMinLevel(DragonflyLogLevel.debug);
      log.addListener(listener);
      log.info('post-init message');
      expect(received, isNotEmpty);
      log.removeListener(listener);
    });

    test('enableLogging false blocks log messages', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      final log = DragonflyLogManager.instance;
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.setMinLevel(DragonflyLogLevel.debug);
      log.addListener(listener);
      log.info('should be blocked');
      expect(received, isEmpty);
      log.removeListener(listener);
    });
  });

  // ── init() with WebSocket adapter logging ───────────────────────────

  group('init with WebSocket adapter logging', () {
    test('init logs WebSocket connection registration when logging enabled', () async {
      const config = DragonflyConfig(
        adapters: [
          DragonflyWebSocketAdapterConfig(
            config: DragonflyRealtimeConfig(url: 'wss://example.com/ws'),
            enableLogging: false,
          ),
        ],
      );
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: true,
      );
      DragonflyLogManager.instance.setPrintToConsole(false);

      await expectLater(app.init(), completes);
    });
  });
}
