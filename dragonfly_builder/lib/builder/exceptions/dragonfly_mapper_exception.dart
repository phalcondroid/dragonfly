class DragonflyMapperException implements Exception {
  final String component;
  final String message;
  final StackTrace stackTrace;

  DragonflyMapperException(
      {this.component = "",
      this.message = "",
      this.stackTrace = StackTrace.empty});

  @override
  String toString() => " [ $component ]: '$message', trace: $stackTrace";
}
