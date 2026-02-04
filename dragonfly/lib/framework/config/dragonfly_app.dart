import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/config/dragonfly_config.dart';
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
    // Initialize logging
    final log = DragonflyLogManager.instance;
    log.setEnabled(enableLogging);
    log.setMinLevel(minLogLevel);

    // Show banner
    if (showBanner && enableLogging) {
      log.printBanner(version: version);
    }

    if (enableLogging) {
      log.info('Initializing Dragonfly Framework...', source: 'DragonflyApp');
    }

    // Initialize instance configurations
    List<DragonflyInstanceConfig> instanceConfig = config.instanceConfigs;
    for (DragonflyInstanceConfig config in instanceConfig) {
      config.initConfig();
    }

    // Run custom injection
    await config.injector?.inject!(DragonflyContainer.I);

    if (enableLogging) {
      log.success('Dragonfly Framework initialized successfully!', source: 'DragonflyApp');
      log.divider();
    }
  }
}
