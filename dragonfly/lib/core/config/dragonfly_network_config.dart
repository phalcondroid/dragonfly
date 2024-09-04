enum DragonflyNetworkIdentify { defaultIdentify }

class DragonflyNetworkConfig {
  final String baseUrl;
  final String identify;
  final double connectionTimeout;
  final bool isSingleton;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic> extra;

  const DragonflyNetworkConfig(
      {required this.baseUrl,
      this.identify = "__df_network_default",
      this.connectionTimeout = 2000,
      this.isSingleton = true,
      this.headers = const {},
      this.extra = const {}});
}
