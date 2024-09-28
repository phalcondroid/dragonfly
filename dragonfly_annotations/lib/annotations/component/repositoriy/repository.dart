import 'package:dragonfly_annotations/enums/network_adapter.dart';

class Repository {
  final String url;
  final NetworkAdapter adapter;
  const Repository({this.url = '', this.adapter = NetworkAdapter.http});
}
