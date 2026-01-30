import 'package:dragonfly/framework/network/enums/dragonfly_network_adapters_enum.dart';

enum DragonflyNetworkIdentify { defaultIdentify }

class DragonflyNetworkConfig {
  final String baseUrl;
  final DragonflyNetworkAdaptersEnum identify;
  final double connectionTimeout;
  final bool isSingleton;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic> extra;

  const DragonflyNetworkConfig(
      {required this.baseUrl,
      this.identify = DragonflyNetworkAdaptersEnum.http,
      this.connectionTimeout = 2000,
      this.isSingleton = true,
      this.headers = const {},
      this.extra = const {}});
}
