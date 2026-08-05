import 'package:dragonfly/framework/config/dragonfly_interceptor.dart';
import 'package:dragonfly/framework/config/dragonfly_network_config.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';
import 'package:dragonfly/framework/exceptions/dragonfly_exception.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_http_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_realtime_adapter.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_web_socket_adapter.dart';
import 'package:dragonfly/framework/network/config/dragonfly_realtime_config.dart';
import 'package:dragonfly/framework/network/enums/dragonfly_network_names_constants.dart';

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
      final DragonflyNetworkConfig config = DragonflyNetworkConfig(
        baseUrl: options.baseUrl,
        connectionTimeout: options.connectTimeout!.inSeconds.toDouble(),
      );
      if (!DragonflyContainer.I.isRegistered<DragonflyNetworkHttpAdapter>(
          instanceName: connectionName)) {
        DragonflyContainer.I.registerSingleton(
            DragonflyNetworkHttpAdapter(config: config),
            instanceName: connectionName);
      }
    } catch (e) {
      throw DragonflyException(message: "$e");
    }
  }
}

/// Registers a realtime (socket) transport under a connection name, the way
/// [DragonflyInstanceConfig] does for HTTP.
///
/// A repository reaches it with `@Repository(realtimeConnection: 'events')`, and
/// generated `Stream`-returning methods resolve it from the container by that
/// name.
///
/// ```dart
/// @override
/// List<DragonflyRealtimeInstanceConfig> get realtimeConfigs => [
///   const DragonflyRealtimeInstanceConfig(
///     config: DragonflyRealtimeConfig(url: 'wss://api.example.com/ws'),
///   ),
/// ];
/// ```
class DragonflyRealtimeInstanceConfig {
  const DragonflyRealtimeInstanceConfig({
    required this.config,
    this.connectionName = defaultRealtimeNetwork,
    this.enableLogging = true,
    this.connectEagerly = false,
  });

  /// Transport settings: URL, envelope shape, reconnect policy.
  final DragonflyRealtimeConfig config;

  /// Name this adapter is registered under.
  final String connectionName;

  /// Whether the adapter logs connection lifecycle and protocol errors.
  final bool enableLogging;

  /// Open the socket during app init instead of on first subscribe.
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

      // Registered under both the interface and the concrete type: generated
      // code asks for the interface, hand-written code may want the impl.
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

class DragonflyInjector {
  final Future<void> Function(DragonflyContainer injector)? inject;

  const DragonflyInjector({
    this.inject,
  });
}

class DragonflyConfig {
  final List<DragonflyInstanceConfig> instanceConfigs;

  /// Realtime transports to register during [DragonflyApp.init].
  final List<DragonflyRealtimeInstanceConfig> realtimeConfigs;

  final DragonflyInjector? injector;

  const DragonflyConfig({
    this.injector,
    this.instanceConfigs = const [],
    this.realtimeConfigs = const [],
  });
}
