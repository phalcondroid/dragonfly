import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/config/dragonfly_config.dart';
import 'package:dragonfly/framework/form/dragonfly_validation_messages.dart';
import 'package:dragonfly/framework/logging/dragonfly_log_manager.dart';

class DragonflyApp {
  final DragonflyConfig config;
  final List<DragonflyLocalStorageConfig>? itemDbConfig;

  /// Whether to show the Dragonfly banner on initialization.
  final bool showBanner;

  /// Whether to enable logging.
  final bool enableLogging;

  /// Minimum log level to display.
  final DragonflyLogLevel minLogLevel;

  /// Framework version for display in banner.
  static const String version = '1.0.0';

  DragonflyApp({
    required this.config,
    this.itemDbConfig,
    this.showBanner = true,
    this.enableLogging = true,
    this.minLogLevel = DragonflyLogLevel.info,
  });

  Future<void> init() async {
    final log = DragonflyLogManager.instance;
    log.setEnabled(enableLogging);
    log.setMinLevel(minLogLevel);

    if (showBanner && enableLogging) {
      log.printBanner(version: version);
    }

    if (enableLogging) {
      log.info('Initializing Dragonfly Framework...', source: 'DragonflyApp');
    }

    final container = DragonflyContainer.I;

    // ── Validation messages (i18n) ────────────────────────────────────────
    if (config.validationMessages != null) {
      Validators.setMessages(config.validationMessages!);
      DragonflySessionManager.setValidationMessages(config.validationMessages!);
    }

    // ── Unified adapters (preferred, extensible) ──────────────────────────
    for (final adapter in config.adapters) {
      adapter.initConfig(container);
      if (enableLogging && adapter is DragonflyWebSocketAdapterConfig) {
        log.info(
          'Realtime connection registered: ${adapter.connectionName} '
          '(${adapter.config.url})',
          source: 'DragonflyApp',
        );
      }
    }

    // ── Backward compat: deprecated instanceConfigs ───────────────────────
    for (final c in config.instanceConfigs) {
      c.initConfig();
    }

    // ── Backward compat: deprecated realtimeConfigs ──────────────────────
    for (final realtime in config.realtimeConfigs) {
      realtime.initConfig();
      if (enableLogging) {
        log.info(
          'Realtime connection registered: ${realtime.connectionName} '
          '(${realtime.config.url})',
          source: 'DragonflyApp',
        );
      }
    }

    // ── Custom injection ─────────────────────────────────────────────────
    await config.injector?.inject!(container);

    if (enableLogging) {
      log.success('Dragonfly Framework initialized successfully!',
          source: 'DragonflyApp');
      log.divider();
    }
  }
}
