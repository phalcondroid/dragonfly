import 'package:dragonfly_annotations/enums/network_adapter.dart';

class Repository {
  final String url;
  final NetworkAdapter adapter;
  final String connection;
  final Type? as;
  final List<String>? env;
  final int? order;
  final String? scope;

  /// default constructor
  const Repository(
      {this.url = '',
      this.connection = "defaultHttpNetwork",
      this.adapter = NetworkAdapter.http,
      this.as,
      this.env,
      this.scope,
      this.order});
}
