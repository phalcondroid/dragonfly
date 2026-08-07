import 'package:dragonfly/framework/config/dragonfly_interceptor.dart';
import 'package:dragonfly/framework/config/dragonfly_network_config.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';
import 'package:dragonfly/framework/exceptions/dragonfly_exception.dart';
import 'package:dragonfly/framework/form/dragonfly_validation_messages.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_base_network_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_http_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_realtime_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_web_socket_adapter.dart';
import 'package:dragonfly/framework/network/config/dragonfly_realtime_config.dart';
import 'package:dragonfly/framework/network/enums/dragonfly_network_names_constants.dart';
import 'package:dragonfly/framework/session/authenticated_network_adapter.dart';

// ── Abstract adapter config — extensible by the community ──────────────────

/// Base class for network adapter configurations.
///
/// Subclass this to register a custom transport adapter — WebRTC, gRPC,
/// GraphQL, MQTT, or any protocol — into the Dragonfly DI container so
/// repositories can resolve it by [DragonflyBaseNetworkAdapter] type and
/// connection name.
///
/// Built-in implementations:
/// - [DragonflyHttpAdapterConfig] — HTTP/S request/response
/// - [DragonflyWebSocketAdapterConfig] — WebSocket streaming + pub/sub
///
/// ```dart
/// class WebRTCAdapterConfig extends DragonflyAdapterConfig {
///   final String connectionName;
///   const WebRTCAdapterConfig({required this.connectionName});
///
///   @override
///   void initConfig(DragonflyContainer container) {
///     container.registerSingleton<DragonflyBaseNetworkAdapter>(
///       WebRTCAdapter(),
///       instanceName: connectionName,
///     );
///   }
/// }
/// ```
abstract class DragonflyAdapterConfig {
  const DragonflyAdapterConfig();

  /// Registers this adapter's implementation(s) in the DI [container].
  ///
  /// Called during [DragonflyApp.init]. Register at least one
  /// [DragonflyBaseNetworkAdapter] so generated repositories can resolve it.
  void initConfig(DragonflyContainer container);
}

// ── HTTP adapter config ────────────────────────────────────────────────────

class DragonflyHttpBaseOptions {
  final String baseUrl;
  final Duration? connectTimeout;
  final Duration? receiveTimeout;

  const DragonflyHttpBaseOptions({
    this.baseUrl = "",
    this.connectTimeout = const Duration(seconds: 5),
    this.receiveTimeout = const Duration(seconds: 3),
  });
}

/// Registers an HTTP adapter and its authenticated counterpart.
///
/// On [initConfig], creates a [DragonflyNetworkHttpAdapter] and an
/// [DragonflyAuthenticatedAdapter], both registered as
/// [DragonflyBaseNetworkAdapter] under [connectionName] and
/// `$connectionName:authenticated` respectively.
class DragonflyHttpAdapterConfig extends DragonflyAdapterConfig {
  final String connectionName;
  final DragonflyHttpBaseOptions options;
  final DragonflyInterceptor? interceptor;

  const DragonflyHttpAdapterConfig({
    required this.options,
    this.connectionName = defaultHttpNetwork,
    this.interceptor = const DragonflyInterceptor(),
  });

  @override
  void initConfig(DragonflyContainer container) {
    try {
      final config = DragonflyNetworkConfig(
        baseUrl: options.baseUrl,
        connectionTimeout:
            (options.connectTimeout ?? const Duration(seconds: 5))
                .inSeconds
                .toDouble(),
      );

      if (container.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: connectionName)) {
        return;
      }

      final adapter = DragonflyNetworkHttpAdapter(config: config);

      container.registerSingleton<DragonflyBaseNetworkAdapter>(
          adapter,
          instanceName: connectionName);
      container.registerSingleton<DragonflyNetworkHttpAdapter>(
          adapter,
          instanceName: connectionName);

      container.registerSingleton<DragonflyBaseNetworkAdapter>(
          AuthenticatedNetworkAdapter(config: config),
          instanceName: '$connectionName:authenticated');
    } catch (e) {
      throw DragonflyException(message: "$e");
    }
  }
}

// ── WebSocket adapter config ───────────────────────────────────────────────

/// Registers a WebSocket (realtime) adapter.
///
/// A repository reaches it with `@Repository(realtimeConnection: 'events')`,
/// and generated `Stream`-returning methods resolve it from the container by
/// that name.
class DragonflyWebSocketAdapterConfig extends DragonflyAdapterConfig {
  const DragonflyWebSocketAdapterConfig({
    required this.config,
    this.connectionName = defaultRealtimeNetwork,
    this.enableLogging = true,
    this.connectEagerly = false,
  });

  final DragonflyRealtimeConfig config;
  final String connectionName;
  final bool enableLogging;
  final bool connectEagerly;

  @override
  void initConfig(DragonflyContainer container) {
    try {
      if (container.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: connectionName)) {
        return;
      }

      final adapter = DragonflyWebSocketAdapter(
        config: config,
        enableLogging: enableLogging,
      );

      container.registerSingleton<DragonflyRealtimeAdapter>(
        adapter,
        instanceName: connectionName,
      );
      container.registerSingleton<DragonflyWebSocketAdapter>(
        adapter,
        instanceName: connectionName,
      );

      if (connectEagerly) {
        adapter.connect();
      }
    } catch (e) {
      throw DragonflyException(message: "$e");
    }
  }
}

// ── Backward-compatible aliases (deprecated) ───────────────────────────────

/// Deprecated — use [DragonflyHttpAdapterConfig] instead.
@Deprecated('Use DragonflyHttpAdapterConfig instead')
class DragonflyInstanceConfig {
  final String connectionName;
  final DragonflyHttpBaseOptions options;
  final DragonflyInterceptor? interceptor;

  const DragonflyInstanceConfig({
    required this.options,
    this.connectionName = defaultHttpNetwork,
    this.interceptor = const DragonflyInterceptor(),
  });

  void initConfig() {
    try {
      final config = DragonflyNetworkConfig(
        baseUrl: options.baseUrl,
        connectionTimeout:
            (options.connectTimeout ?? const Duration(seconds: 5))
                .inSeconds
                .toDouble(),
      );
      if (DragonflyContainer.I.isRegistered<DragonflyBaseNetworkAdapter>(
          instanceName: connectionName)) {
        return;
      }

      final adapter = DragonflyNetworkHttpAdapter(config: config);
      DragonflyContainer.I.registerSingleton<DragonflyBaseNetworkAdapter>(
          adapter,
          instanceName: connectionName);
      DragonflyContainer.I.registerSingleton<DragonflyNetworkHttpAdapter>(
          adapter,
          instanceName: connectionName);
      DragonflyContainer.I.registerSingleton<DragonflyBaseNetworkAdapter>(
          AuthenticatedNetworkAdapter(config: config),
          instanceName: '$connectionName:authenticated');
    } catch (e) {
      throw DragonflyException(message: "$e");
    }
  }
}

/// Deprecated — use [DragonflyWebSocketAdapterConfig] instead.
@Deprecated('Use DragonflyWebSocketAdapterConfig instead')
class DragonflyRealtimeInstanceConfig {
  const DragonflyRealtimeInstanceConfig({
    required this.config,
    this.connectionName = defaultRealtimeNetwork,
    this.enableLogging = true,
    this.connectEagerly = false,
  });

  final DragonflyRealtimeConfig config;
  final String connectionName;
  final bool enableLogging;
  final bool connectEagerly;

  void initConfig() {
    try {
      if (DragonflyContainer.I.isRegistered<DragonflyRealtimeAdapter>(
          instanceName: connectionName)) {
        return;
      }

      final adapter = DragonflyWebSocketAdapter(
        config: config,
        enableLogging: enableLogging,
      );

      DragonflyContainer.I.registerSingleton<DragonflyRealtimeAdapter>(
        adapter,
        instanceName: connectionName,
      );
      DragonflyContainer.I.registerSingleton<DragonflyWebSocketAdapter>(
        adapter,
        instanceName: connectionName,
      );

      if (connectEagerly) {
        adapter.connect();
      }
    } catch (e) {
      throw DragonflyException(message: "$e");
    }
  }
}

// ── DI & app config ────────────────────────────────────────────────────────

class DragonflyInjector {
  final Future<void> Function(DragonflyContainer injector)? inject;

  const DragonflyInjector({
    this.inject,
  });
}

class DragonflyConfig {
  /// Unified list of adapter configs — HTTP, WebSocket, custom.
  ///
  /// Each config's [DragonflyAdapterConfig.initConfig] is called during
  /// [DragonflyApp.init] to register its adapter(s) in the DI container.
  ///
  /// Prefer this over the deprecated [instanceConfigs] and [realtimeConfigs].
  final List<DragonflyAdapterConfig> adapters;

  /// Deprecated — use [adapters] with [DragonflyHttpAdapterConfig] instead.
  @Deprecated('Use adapters with DragonflyHttpAdapterConfig instead')
  final List<DragonflyInstanceConfig> instanceConfigs;

  /// Deprecated — use [adapters] with [DragonflyWebSocketAdapterConfig] instead.
  @Deprecated('Use adapters with DragonflyWebSocketAdapterConfig instead')
  final List<DragonflyRealtimeInstanceConfig> realtimeConfigs;

  final DragonflyInjector? injector;

  /// Translated validation error messages and UI labels.
  ///
  /// Set this to a locale-specific [DragonflyValidationMessages] instance
  /// (e.g., from your [DragonflyI18n] subclass) to localize all form
  /// validation errors, the submit button label, and ACL access-denied
  /// messages.
  ///
  /// If null (default), English messages are used.
  final DragonflyValidationMessages? validationMessages;

  const DragonflyConfig({
    this.injector,
    this.adapters = const [],
    this.validationMessages,
    @Deprecated('Use adapters instead')
    this.instanceConfigs = const [],
    @Deprecated('Use adapters instead')
    this.realtimeConfigs = const [],
  });
}
