import 'package:dragonfly/framework/config/dragonfly_interceptor.dart';
import 'package:dragonfly/framework/config/dragonfly_network_config.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart';
import 'package:dragonfly/framework/exceptions/dragonfly_exception.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_network_http_adapter.dart';
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

  void initConfig(DragonflyContainer container) {
    try {
      final DragonflyNetworkConfig config = DragonflyNetworkConfig(
        baseUrl: options.baseUrl,
        connectionTimeout: options.connectTimeout!.inSeconds.toDouble(),
      );
      container.registerSingleton(DragonflyNetworkHttpAdapter(config: config),
          instanceName: connectionName);
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
  final DragonflyInjector? injector;
  const DragonflyConfig({this.injector, this.instanceConfigs = const []});
}
