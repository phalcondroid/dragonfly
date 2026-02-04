/// Log levels for the Dragonfly framework.
///
/// Each level has an associated priority for filtering and a semantic meaning.
enum DragonflyLogLevel {
  /// Detailed information for debugging purposes.
  debug(0, 'DEBUG'),

  /// General information about application flow.
  info(1, 'INFO'),

  /// Successful operations.
  success(2, 'SUCCESS'),

  /// Warning conditions that should be addressed.
  warning(3, 'WARNING'),

  /// Error conditions that might still allow the app to continue.
  error(4, 'ERROR'),

  /// Critical errors that require immediate attention.
  danger(5, 'DANGER'),

  /// Network request information.
  request(1, 'REQUEST'),

  /// Network response information.
  response(1, 'RESPONSE');

  const DragonflyLogLevel(this.priority, this.label);

  /// The priority level (higher = more severe).
  final int priority;

  /// Human-readable label for the log level.
  final String label;
}
