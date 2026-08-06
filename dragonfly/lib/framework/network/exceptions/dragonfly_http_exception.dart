/// HTTP exception with status code and response body, thrown by the network
/// adapters when a response status is >= 400.
class DragonflyHttpException implements Exception {
  final String message;
  final int statusCode;
  final String body;

  const DragonflyHttpException(this.message, this.statusCode, this.body);

  @override
  String toString() => 'DragonflyHttpException: $message';
}
