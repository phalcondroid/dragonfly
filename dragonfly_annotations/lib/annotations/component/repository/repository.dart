import 'package:dragonfly_annotations/enums/network_adapter.dart';

class Repository {
  final String url;
  final NetworkAdapter adapter;
  final String connection;
  final Type? as;
  final List<String>? env;
  final int? order;
  final String? scope;

  /// The name to register this repository under.
  /// Use this when you need multiple repositories of the same interface.
  /// 
  /// Example:
  /// ```dart
  /// @Repository(as: UserRepository, instanceName: 'api')
  /// abstract interface class ApiUserRepository implements UserRepository {}
  /// ```
  final String? instanceName;

  /// Connection name of the realtime transport used by this repository's
  /// `@Subscribe` methods. Must match a `DragonflyRealtimeInstanceConfig`
  /// registered in the app config.
  final String realtimeConnection;

  /// default constructor
  const Repository({
    this.url = '',
    this.connection = "defaultHttpNetwork",
    this.realtimeConnection = "defaultRealtimeNetwork",
    this.adapter = NetworkAdapter.http,
    this.as,
    this.env,
    this.scope,
    this.order,
    this.instanceName,
  });
}
