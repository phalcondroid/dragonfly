import 'package:dragonfly_annotations/enums/network_adapter.dart';

class Repository {
  final String url;
  final String path;
  final NetworkAdapter adapter;
  const Repository(
      {this.url = '', this.path = '', this.adapter = NetworkAdapter.http});
}
