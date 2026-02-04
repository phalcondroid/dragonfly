import 'dragonfly_log_level.dart';

/// Represents a single log entry in the Dragonfly logging system.
class DragonflyLogEntry {
  /// The log level/severity.
  final DragonflyLogLevel level;

  /// The main message.
  final String message;

  /// Optional tag/category for the log.
  final String? tag;

  /// Additional data to display.
  final Map<String, dynamic>? data;

  /// Stack trace for errors.
  final StackTrace? stackTrace;

  /// Error object if this is an error log.
  final Object? error;

  /// Timestamp when the log was created.
  final DateTime timestamp;

  /// Source of the log (class/method name).
  final String? source;

  DragonflyLogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.data,
    this.stackTrace,
    this.error,
    this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '[$level] $message';
}

/// Network request log entry with detailed request information.
class DragonflyNetworkRequestLog extends DragonflyLogEntry {
  /// HTTP method (GET, POST, etc.).
  final String method;

  /// Request URL.
  final String url;

  /// Request headers.
  final Map<String, String>? headers;

  /// Request body/params.
  final dynamic body;

  /// Query parameters.
  final Map<String, dynamic>? queryParams;

  /// Request ID for correlation.
  final String requestId;

  DragonflyNetworkRequestLog({
    required this.method,
    required this.url,
    required this.requestId,
    this.headers,
    this.body,
    this.queryParams,
    String? source,
  }) : super(
          level: DragonflyLogLevel.request,
          message: '$method $url',
          tag: 'HTTP',
          source: source,
        );
}

/// Network response log entry with detailed response information.
class DragonflyNetworkResponseLog extends DragonflyLogEntry {
  /// HTTP status code.
  final int statusCode;

  /// Status message.
  final String? statusMessage;

  /// Response headers.
  final Map<String, String>? headers;

  /// Response body.
  final dynamic body;

  /// Request duration in milliseconds.
  final int durationMs;

  /// Original request ID for correlation.
  final String requestId;

  /// Original request URL.
  final String url;

  /// Original HTTP method.
  final String method;

  DragonflyNetworkResponseLog({
    required this.statusCode,
    required this.durationMs,
    required this.requestId,
    required this.url,
    required this.method,
    this.statusMessage,
    this.headers,
    this.body,
    String? source,
  }) : super(
          level: DragonflyLogLevel.response,
          message: '$statusCode ${statusMessage ?? ''} ($durationMs ms)',
          tag: 'HTTP',
          source: source,
        );

  /// Returns true if the response indicates success (2xx).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Returns true if the response indicates a client error (4xx).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Returns true if the response indicates a server error (5xx).
  bool get isServerError => statusCode >= 500;
}

/// Repository operation log entry.
class DragonflyRepositoryLog extends DragonflyLogEntry {
  /// Repository class name.
  final String repository;

  /// Method being called.
  final String methodName;

  /// Operation parameters.
  final Map<String, dynamic>? params;

  /// Operation result (if successful).
  final dynamic result;

  /// Duration of the operation in milliseconds.
  final int? durationMs;

  DragonflyRepositoryLog({
    required DragonflyLogLevel level,
    required this.repository,
    required this.methodName,
    required String message,
    this.params,
    this.result,
    this.durationMs,
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          level: level,
          message: message,
          tag: 'Repository',
          source: '$repository.$methodName',
          error: error,
          stackTrace: stackTrace,
        );
}
