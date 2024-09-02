class Post {
  final String path;
  final Map<String, String>? headers;
  const Post({
    this.headers,
    this.path = ""
  });
}