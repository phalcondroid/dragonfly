import 'dart:async';
import 'dart:math';
import 'dragonfly_log_entry.dart';
import 'dragonfly_log_formatter.dart';
import 'dragonfly_log_level.dart';

/// Callback type for log listeners.
typedef DragonflyLogListener = void Function(DragonflyLogEntry entry);

/// The main logging manager for the Dragonfly framework.
///
/// Provides beautiful, colored, indented logging with support for:
/// - Different log levels (debug, info, success, warning, error, danger)
/// - Network request/response logging
/// - Repository operation logging
/// - Custom log listeners
///
/// Example:
/// ```dart
/// final log = DragonflyLogManager.instance;
///
/// log.info('Application started');
/// log.success('User logged in', data: {'userId': '123'});
/// log.warning('Cache expired');
/// log.error('Failed to load data', error: exception, stackTrace: stack);
/// ```
class DragonflyLogManager {
  DragonflyLogManager._();

  static DragonflyLogManager? _instance;

  /// Get the singleton instance of the log manager.
  static DragonflyLogManager get instance {
    _instance ??= DragonflyLogManager._();
    return _instance!;
  }

  /// Shorthand accessor for the singleton instance.
  static DragonflyLogManager get I => instance;

  /// Whether logging is enabled.
  bool _enabled = true;

  /// Minimum log level to display.
  DragonflyLogLevel _minLevel = DragonflyLogLevel.debug;

  /// Whether to show timestamps in logs.
  // ignore: unused_field
  bool _showTimestamp = true;

  /// Whether to print to console.
  bool _printToConsole = true;

  /// Log listeners for custom log handling.
  final List<DragonflyLogListener> _listeners = [];

  /// Log history (if enabled).
  final List<DragonflyLogEntry> _history = [];

  /// Whether to keep log history.
  bool _keepHistory = false;

  /// Maximum history size.
  int _maxHistorySize = 1000;

  /// Stream controller for log entries.
  final _logStreamController = StreamController<DragonflyLogEntry>.broadcast();

  /// Stream of all log entries.
  Stream<DragonflyLogEntry> get logStream => _logStreamController.stream;

  /// Get log history.
  List<DragonflyLogEntry> get history => List.unmodifiable(_history);

  // ─────────────────────────────────────────────────────────────────
  // Configuration
  // ─────────────────────────────────────────────────────────────────

  /// Enable or disable logging.
  void setEnabled(bool enabled) => _enabled = enabled;

  /// Set the minimum log level.
  void setMinLevel(DragonflyLogLevel level) => _minLevel = level;

  /// Enable or disable timestamps.
  void setShowTimestamp(bool show) => _showTimestamp = show;

  /// Enable or disable console printing.
  void setPrintToConsole(bool print) => _printToConsole = print;

  /// Enable log history.
  void enableHistory({int maxSize = 1000}) {
    _keepHistory = true;
    _maxHistorySize = maxSize;
  }

  /// Disable log history.
  void disableHistory() {
    _keepHistory = false;
    _history.clear();
  }

  /// Clear log history.
  void clearHistory() => _history.clear();

  /// Add a log listener.
  void addListener(DragonflyLogListener listener) => _listeners.add(listener);

  /// Remove a log listener.
  void removeListener(DragonflyLogListener listener) => _listeners.remove(listener);

  // ─────────────────────────────────────────────────────────────────
  // Core Logging Methods
  // ─────────────────────────────────────────────────────────────────

  /// Log a message at debug level.
  void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    String? source,
  }) {
    _log(DragonflyLogEntry(
      level: DragonflyLogLevel.debug,
      message: message,
      tag: tag,
      data: data,
      source: source,
    ));
  }

  /// Log a message at info level.
  void info(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    String? source,
  }) {
    _log(DragonflyLogEntry(
      level: DragonflyLogLevel.info,
      message: message,
      tag: tag,
      data: data,
      source: source,
    ));
  }

  /// Log a success message.
  void success(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    String? source,
  }) {
    _log(DragonflyLogEntry(
      level: DragonflyLogLevel.success,
      message: message,
      tag: tag,
      data: data,
      source: source,
    ));
  }

  /// Log a warning message.
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    String? source,
  }) {
    _log(DragonflyLogEntry(
      level: DragonflyLogLevel.warning,
      message: message,
      tag: tag,
      data: data,
      source: source,
    ));
  }

  /// Log an error message.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? data,
    String? source,
  }) {
    _log(DragonflyLogEntry(
      level: DragonflyLogLevel.error,
      message: message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
      source: source,
    ));
  }

  /// Log a critical/danger message.
  void danger(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? data,
    String? source,
  }) {
    _log(DragonflyLogEntry(
      level: DragonflyLogLevel.danger,
      message: message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
      source: source,
    ));
  }

  // ─────────────────────────────────────────────────────────────────
  // Network Logging
  // ─────────────────────────────────────────────────────────────────

  /// Generate a unique request ID.
  String generateRequestId() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Log an HTTP request.
  void request({
    required String method,
    required String url,
    String? requestId,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParams,
    String? source,
  }) {
    final entry = DragonflyNetworkRequestLog(
      method: method,
      url: url,
      requestId: requestId ?? generateRequestId(),
      headers: headers,
      body: body,
      queryParams: queryParams,
      source: source,
    );
    _logNetwork(entry);
  }

  /// Log an HTTP response.
  void response({
    required int statusCode,
    required int durationMs,
    required String requestId,
    required String url,
    required String method,
    String? statusMessage,
    Map<String, String>? headers,
    dynamic body,
    String? source,
  }) {
    final entry = DragonflyNetworkResponseLog(
      statusCode: statusCode,
      durationMs: durationMs,
      requestId: requestId,
      url: url,
      method: method,
      statusMessage: statusMessage,
      headers: headers,
      body: body,
      source: source,
    );
    _logNetwork(entry);
  }

  // ─────────────────────────────────────────────────────────────────
  // Repository Logging
  // ─────────────────────────────────────────────────────────────────

  /// Log a repository operation start.
  void repositoryStart({
    required String repository,
    required String method,
    Map<String, dynamic>? params,
  }) {
    _log(DragonflyRepositoryLog(
      level: DragonflyLogLevel.info,
      repository: repository,
      methodName: method,
      message: 'Starting operation',
      params: params,
    ));
  }

  /// Log a repository operation success.
  void repositorySuccess({
    required String repository,
    required String method,
    required String message,
    int? durationMs,
    dynamic result,
    Map<String, dynamic>? params,
  }) {
    final entry = DragonflyRepositoryLog(
      level: DragonflyLogLevel.success,
      repository: repository,
      methodName: method,
      message: message,
      durationMs: durationMs,
      result: result,
      params: params,
    );
    _logRepository(entry);
  }

  /// Log a repository operation warning.
  void repositoryWarning({
    required String repository,
    required String method,
    required String message,
    int? durationMs,
    Map<String, dynamic>? params,
  }) {
    final entry = DragonflyRepositoryLog(
      level: DragonflyLogLevel.warning,
      repository: repository,
      methodName: method,
      message: message,
      durationMs: durationMs,
      params: params,
    );
    _logRepository(entry);
  }

  /// Log a repository operation error.
  void repositoryError({
    required String repository,
    required String method,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    int? durationMs,
    Map<String, dynamic>? params,
  }) {
    final entry = DragonflyRepositoryLog(
      level: DragonflyLogLevel.error,
      repository: repository,
      methodName: method,
      message: message,
      durationMs: durationMs,
      params: params,
      error: error,
      stackTrace: stackTrace,
    );
    _logRepository(entry);
  }

  // ─────────────────────────────────────────────────────────────────
  // View Logging
  // ─────────────────────────────────────────────────────────────────

  /// Log view initialization.
  void viewInit({required String viewName, required String initialState}) {
    if (!_enabled || !_printToConsole) return;
    _printViewLog('🚀 INIT', viewName, 'Initial state: ${_truncateState(initialState)}');
  }

  /// Log the start of a view action.
  void viewActionStart({
    required String viewName,
    required String actionName,
    Map<String, dynamic>? params,
  }) {
    if (!_enabled || !_printToConsole) return;
    final paramsStr = params != null && params.isNotEmpty
        ? '\n│     Params: ${_formatParams(params)}'
        : '';
    _printViewLog('▶️  ACTION', viewName, '$actionName()$paramsStr', isStart: true);
  }

  /// Log the end of a view action.
  void viewActionEnd({
    required String viewName,
    required String actionName,
    int? durationMs,
    bool success = true,
    String? error,
  }) {
    if (!_enabled || !_printToConsole) return;
    final icon = success ? '✅' : '❌';
    final status = success ? 'SUCCESS' : 'FAILED';
    final duration = durationMs != null ? ' (${durationMs}ms)' : '';
    final errorStr = error != null ? '\n│     Error: $error' : '';
    _printViewLog('$icon $status', viewName, '$actionName()$duration$errorStr', isEnd: true);
  }

  /// Log a step within an action.
  void viewStep({
    required String viewName,
    required String step,
    Map<String, dynamic>? data,
  }) {
    if (!_enabled || !_printToConsole) return;
    final dataStr = data != null && data.isNotEmpty
        ? ' → ${_formatParams(data)}'
        : '';
    // ignore: avoid_print
    print('│  ├─ 📌 $step$dataStr');
  }

  /// Log a state change.
  void viewStateChange({
    required String viewName,
    required String previousState,
    required String newState,
  }) {
    if (!_enabled || !_printToConsole) return;
    // ignore: avoid_print
    print('│  ├─ 🔄 State: ${_truncateState(previousState)} → ${_truncateState(newState)}');
  }

  /// Log a side effect.
  void viewSideEffect({required String viewName, required String effect}) {
    if (!_enabled || !_printToConsole) return;
    // ignore: avoid_print
    print('│  ├─ ⚡ SideEffect: $effect');
  }

  /// Log a use case call.
  void viewUseCase({required String viewName, required String useCaseName}) {
    if (!_enabled || !_printToConsole) return;
    // ignore: avoid_print
    print('│  ├─ 🔧 UseCase: $useCaseName');
  }

  /// Log subscription start.
  void viewSubscribe({required String viewName, required String subscriptionKey}) {
    if (!_enabled || !_printToConsole) return;
    // ignore: avoid_print
    print('│  ├─ 📡 Subscribe: $subscriptionKey');
  }

  /// Log subscription error.
  void viewSubscriptionError({
    required String viewName,
    required String subscriptionKey,
    required String error,
  }) {
    if (!_enabled || !_printToConsole) return;
    // ignore: avoid_print
    print('│  ├─ ❌ Subscription error ($subscriptionKey): $error');
  }

  /// Log subscription done.
  void viewSubscriptionDone({required String viewName, required String subscriptionKey}) {
    if (!_enabled || !_printToConsole) return;
    // ignore: avoid_print
    print('│  ├─ ✓ Subscription done: $subscriptionKey');
  }

  /// Log cancel subscription.
  void viewCancelSubscription({required String viewName, required String subscriptionKey}) {
    if (!_enabled || !_printToConsole) return;
    // ignore: avoid_print
    print('│  ├─ 🛑 Cancel subscription: $subscriptionKey');
  }

  /// Log view disposal.
  void viewDispose({required String viewName}) {
    if (!_enabled || !_printToConsole) return;
    _printViewLog('🗑️  DISPOSE', viewName, 'View disposed');
  }

  /// Helper to print view log with consistent formatting.
  void _printViewLog(String icon, String viewName, String message, {bool isStart = false, bool isEnd = false}) {
    if (isStart) {
      // ignore: avoid_print
      print('╭─── $icon [$viewName] ───────────────────────────');
      // ignore: avoid_print
      print('│  $message');
    } else if (isEnd) {
      // ignore: avoid_print
      print('│  $message');
      // ignore: avoid_print
      print('╰──────────────────────────────────────────────────');
    } else {
      // ignore: avoid_print
      print('├── $icon [$viewName] $message');
    }
  }

  /// Truncate state for display.
  String _truncateState(String state) {
    // Extract just the state class name if it's a long string
    final match = RegExp(r'^(\w+)\(').firstMatch(state);
    if (match != null) {
      return match.group(1) ?? state;
    }
    if (state.length > 50) {
      return '${state.substring(0, 47)}...';
    }
    return state;
  }

  /// Format params for display.
  String _formatParams(Map<String, dynamic> params) {
    return params.entries.map((e) {
      final value = e.value.toString();
      final displayValue = value.length > 30 ? '${value.substring(0, 27)}...' : value;
      return '${e.key}: $displayValue';
    }).join(', ');
  }

  // ─────────────────────────────────────────────────────────────────
  // Framework Banner
  // ─────────────────────────────────────────────────────────────────

  /// Print the Dragonfly framework banner.
  void printBanner({String? version}) {
    if (!_enabled || !_printToConsole) return;

    final versionText = version != null ? '• v$version' : '';

    const banner = '''

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ██████╗ ██████╗  █████╗  ██████╗  ██████╗ ███╗   ██╗   ║
║   ██╔══██╗██╔══██╗██╔══██╗██╔════╝ ██╔═══██╗████╗  ██║   ║
║   ██║  ██║██████╔╝███████║██║  ███╗██║   ██║██╔██╗ ██║   ║
║   ██║  ██║██╔══██╗██╔══██║██║   ██║██║   ██║██║╚██╗██║   ║
║   ██████╔╝██║  ██║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║   ║
║   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ║
║                                                           ║''';

    // ignore: avoid_print
    print(banner);
    // ignore: avoid_print
    print('║   🦋 Flutter Framework $versionText${' ' * (35 - versionText.length)}║');
    // ignore: avoid_print
    print('║                                                           ║');
    // ignore: avoid_print
    print('╚═══════════════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');
  }

  /// Print a section divider.
  void divider([String? title]) {
    if (!_enabled || !_printToConsole) return;

    if (title != null) {
      // ignore: avoid_print
      print('── $title ${'─' * (50 - title.length)}');
    } else {
      // ignore: avoid_print
      print('─' * 55);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Internal Methods
  // ─────────────────────────────────────────────────────────────────

  void _log(DragonflyLogEntry entry) {
    if (!_enabled) return;
    if (entry.level.priority < _minLevel.priority) return;

    // Add to history
    if (_keepHistory) {
      _history.add(entry);
      if (_history.length > _maxHistorySize) {
        _history.removeAt(0);
      }
    }

    // Notify listeners
    for (final listener in _listeners) {
      listener(entry);
    }

    // Add to stream
    _logStreamController.add(entry);

    // Print to console
    if (_printToConsole) {
      final formatted = DragonflyLogFormatter.format(entry);
      // ignore: avoid_print
      print(formatted);
    }
  }

  void _logNetwork(DragonflyLogEntry entry) {
    if (!_enabled) return;

    // Add to history
    if (_keepHistory) {
      _history.add(entry);
      if (_history.length > _maxHistorySize) {
        _history.removeAt(0);
      }
    }

    // Notify listeners
    for (final listener in _listeners) {
      listener(entry);
    }

    // Add to stream
    _logStreamController.add(entry);

    // Print to console
    if (_printToConsole) {
      String formatted;
      if (entry is DragonflyNetworkRequestLog) {
        formatted = DragonflyLogFormatter.formatRequest(entry);
      } else if (entry is DragonflyNetworkResponseLog) {
        formatted = DragonflyLogFormatter.formatResponse(entry);
      } else {
        formatted = DragonflyLogFormatter.format(entry);
      }
      // ignore: avoid_print
      print(formatted);
    }
  }

  void _logRepository(DragonflyRepositoryLog entry) {
    if (!_enabled) return;

    // Add to history
    if (_keepHistory) {
      _history.add(entry);
      if (_history.length > _maxHistorySize) {
        _history.removeAt(0);
      }
    }

    // Notify listeners
    for (final listener in _listeners) {
      listener(entry);
    }

    // Add to stream
    _logStreamController.add(entry);

    // Print to console
    if (_printToConsole) {
      final formatted = DragonflyLogFormatter.formatRepository(entry);
      // ignore: avoid_print
      print(formatted);
    }
  }

  /// Dispose the log manager.
  void dispose() {
    _logStreamController.close();
    _listeners.clear();
    _history.clear();
  }
}

/// Global accessor for the log manager.
DragonflyLogManager get dragonflyLog => DragonflyLogManager.instance;
