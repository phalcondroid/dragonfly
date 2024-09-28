class DragonflyException implements Exception {
  final String component;
  final String message;
  final StackTrace stackTrace;

  const DragonflyException(
      {this.component = "",
      this.message = "",
      this.stackTrace = StackTrace.empty});

  @override
  String toString() => " [ $component ]: '$message', trace: $stackTrace";
}