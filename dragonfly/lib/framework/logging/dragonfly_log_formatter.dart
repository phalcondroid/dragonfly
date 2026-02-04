import 'dart:convert';
import 'dragonfly_log_entry.dart';
import 'dragonfly_log_level.dart';

/// Formats log entries for beautiful terminal output.
///
/// Works without ANSI colors by default for maximum compatibility
/// with Flutter debug console, VSCode, and other environments.
class DragonflyLogFormatter {
  DragonflyLogFormatter._();

  /// Whether to use ANSI colors (disabled by default for Flutter compatibility).
  static bool useColors = false;

  /// Box drawing characters for beautiful borders.
  static const String topLeft = '╭';
  static const String topRight = '╮';
  static const String bottomLeft = '╰';
  static const String bottomRight = '╯';
  static const String horizontal = '─';
  static const String vertical = '│';
  static const String teeRight = '├';
  static const String teeLeft = '┤';

  /// Emoji icons for log levels.
  static const Map<DragonflyLogLevel, String> levelIcons = {
    DragonflyLogLevel.debug: '🔍',
    DragonflyLogLevel.info: 'ℹ️',
    DragonflyLogLevel.success: '✅',
    DragonflyLogLevel.warning: '⚠️',
    DragonflyLogLevel.error: '❌',
    DragonflyLogLevel.danger: '🔥',
    DragonflyLogLevel.request: '📤',
    DragonflyLogLevel.response: '📥',
  };

  /// Format a simple log entry.
  static String format(DragonflyLogEntry entry) {
    final buffer = StringBuffer();
    final icon = levelIcons[entry.level] ?? '•';

    // Header line
    final timestamp = _formatTimestamp(entry.timestamp);
    final source = entry.source != null ? '[${entry.source}] ' : '';

    buffer.writeln('$topLeft$horizontal$horizontal '
        '$icon ${entry.level.label.toUpperCase()} '
        '$timestamp '
        '$source');

    // Message
    buffer.writeln('$vertical   ${entry.message}');

    // Data if present
    if (entry.data != null && entry.data!.isNotEmpty) {
      buffer.writeln('$teeRight$horizontal Data:');
      _formatMap(buffer, entry.data!, 1);
    }

    // Error if present
    if (entry.error != null) {
      buffer.writeln('$teeRight$horizontal Error: ${entry.error}');
    }

    // Stack trace if present
    if (entry.stackTrace != null) {
      buffer.writeln('$teeRight$horizontal Stack trace:');
      final lines = entry.stackTrace.toString().split('\n').take(5);
      for (final line in lines) {
        buffer.writeln('$vertical     $line');
      }
    }

    // Footer
    buffer.write('$bottomLeft${horizontal * 40}');

    return buffer.toString();
  }

  /// Format a network request log.
  static String formatRequest(DragonflyNetworkRequestLog entry) {
    final buffer = StringBuffer();

    const width = 60;
    final border = horizontal * width;

    buffer.writeln();
    buffer.writeln('$topLeft$border$topRight');
    buffer.writeln(
        '$vertical 📤 REQUEST  [${entry.requestId}]${' ' * (width - 22 - entry.requestId.length)}$vertical');
    buffer.writeln('$teeRight$border$teeLeft');

    // Method and URL
    final methodUrl = '${entry.method.padRight(7)} ${entry.url}';
    buffer.writeln(
        '$vertical   ${_truncate(methodUrl, width - 4)}${' ' * (width - _truncate(methodUrl, width - 4).length - 3)}$vertical');

    // Query params
    if (entry.queryParams != null && entry.queryParams!.isNotEmpty) {
      buffer.writeln(
          '$teeRight$horizontal Query Parameters${horizontal * (width - 18)}$teeLeft');
      _formatMapInBox(buffer, entry.queryParams!, width);
    }

    // Headers
    if (entry.headers != null && entry.headers!.isNotEmpty) {
      buffer.writeln(
          '$teeRight$horizontal Headers${horizontal * (width - 9)}$teeLeft');
      _formatMapInBox(buffer, entry.headers!, width);
    }

    // Body
    if (entry.body != null) {
      buffer.writeln(
          '$teeRight$horizontal Body${horizontal * (width - 6)}$teeLeft');
      _formatBodyInBox(buffer, entry.body, width);
    }

    // Footer
    buffer.writeln('$bottomLeft$border$bottomRight');

    return buffer.toString();
  }

  /// Format a network response log.
  static String formatResponse(DragonflyNetworkResponseLog entry) {
    final buffer = StringBuffer();

    const width = 60;
    final border = horizontal * width;

    // Determine status indicator
    String statusIcon;
    if (entry.isSuccess) {
      statusIcon = '✅';
    } else if (entry.isClientError) {
      statusIcon = '⚠️';
    } else if (entry.isServerError) {
      statusIcon = '🔥';
    } else {
      statusIcon = 'ℹ️';
    }

    buffer.writeln();
    buffer.writeln('$topLeft$border$topRight');
    buffer.writeln(
        '$vertical 📥 RESPONSE [${entry.requestId}]${' ' * (width - 23 - entry.requestId.length)}$vertical');
    buffer.writeln('$teeRight$border$teeLeft');

    // Status line
    final statusLine =
        '$statusIcon ${entry.statusCode} ${entry.statusMessage ?? 'OK'} (${entry.durationMs}ms)';
    buffer.writeln(
        '$vertical   ${_truncate(statusLine, width - 4)}${' ' * (width - _truncate(statusLine, width - 4).length - 3)}$vertical');

    // Original request reference
    final refLine = '← ${entry.method} ${entry.url}';
    buffer.writeln(
        '$vertical   ${_truncate(refLine, width - 4)}${' ' * (width - _truncate(refLine, width - 4).length - 3)}$vertical');

    // Headers (limited)
    if (entry.headers != null && entry.headers!.isNotEmpty) {
      buffer.writeln(
          '$teeRight$horizontal Response Headers${horizontal * (width - 18)}$teeLeft');
      final limitedHeaders = Map.fromEntries(entry.headers!.entries.take(5));
      _formatMapInBox(buffer, limitedHeaders, width);
      if (entry.headers!.length > 5) {
        buffer.writeln(
            '$vertical     ... and ${entry.headers!.length - 5} more headers${' ' * (width - 25 - (entry.headers!.length - 5).toString().length)}$vertical');
      }
    }

    // Body preview
    if (entry.body != null) {
      buffer.writeln(
          '$teeRight$horizontal Response Body${horizontal * (width - 15)}$teeLeft');
      _formatBodyInBox(buffer, entry.body, width, maxLines: 8);
    }

    // Footer
    buffer.writeln('$bottomLeft$border$bottomRight');

    return buffer.toString();
  }

  /// Format a repository operation log.
  static String formatRepository(DragonflyRepositoryLog entry) {
    final buffer = StringBuffer();

    const width = 50;
    final border = horizontal * width;
    final icon = levelIcons[entry.level] ?? '•';

    buffer.writeln();
    buffer.writeln('$topLeft$border$topRight');
    buffer.writeln(
        '$vertical $icon ${entry.level.label.toUpperCase()}  Repository${' ' * (width - 16 - entry.level.label.length)}$vertical');
    buffer.writeln('$teeRight$border$teeLeft');

    // Repository and method
    final methodLine = '${entry.repository}.${entry.methodName}()';
    buffer.writeln(
        '$vertical   ${_truncate(methodLine, width - 4)}${' ' * (width - _truncate(methodLine, width - 4).length - 3)}$vertical');

    // Duration if present
    if (entry.durationMs != null) {
      final durationLine = '⏱️  ${entry.durationMs}ms';
      buffer.writeln(
          '$vertical   $durationLine${' ' * (width - durationLine.length - 4)}$vertical');
    }

    // Parameters
    if (entry.params != null && entry.params!.isNotEmpty) {
      buffer.writeln(
          '$teeRight$horizontal Parameters${horizontal * (width - 12)}$teeLeft');
      _formatMapInBox(buffer, entry.params!, width);
    }

    // Message
    buffer.writeln(
        '$teeRight$horizontal Message${horizontal * (width - 9)}$teeLeft');
    buffer.writeln(
        '$vertical   ${_truncate(entry.message, width - 4)}${' ' * (width - _truncate(entry.message, width - 4).length - 3)}$vertical');

    // Error if present
    if (entry.error != null) {
      buffer.writeln(
          '$teeRight$horizontal Error${horizontal * (width - 7)}$teeLeft');
      buffer.writeln(
          '$vertical   ${_truncate(entry.error.toString(), width - 4)}${' ' * (width - _truncate(entry.error.toString(), width - 4).length - 3)}$vertical');
    }

    // Stack trace if present (limited)
    if (entry.stackTrace != null) {
      buffer.writeln(
          '$teeRight$horizontal Stack Trace${horizontal * (width - 13)}$teeLeft');
      final lines = entry.stackTrace.toString().split('\n').take(3);
      for (final line in lines) {
        buffer.writeln(
            '$vertical   ${_truncate(line, width - 4)}${' ' * (width - _truncate(line, width - 4).length - 3)}$vertical');
      }
    }

    buffer.writeln('$bottomLeft$border$bottomRight');

    return buffer.toString();
  }

  /// Format timestamp.
  static String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Truncate string to max length.
  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Format a map with indentation.
  static void _formatMap(
      StringBuffer buffer, Map<String, dynamic> map, int indent) {
    final padding = '  ' * indent;

    for (final entry in map.entries) {
      buffer.writeln('$vertical$padding  ${entry.key}: ${entry.value}');
    }
  }

  /// Format a map inside the box.
  static void _formatMapInBox(StringBuffer buffer, Map map, int width) {
    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value.toString();
      final maxValueLen = width - key.length - 10;
      final displayValue =
          _truncate(value, maxValueLen > 10 ? maxValueLen : 10);
      final line = '$key: $displayValue';
      buffer.writeln(
          '$vertical     ${_truncate(line, width - 6)}${' ' * (width - _truncate(line, width - 6).length - 5)}$vertical');
    }
  }

  /// Format body content inside the box.
  static void _formatBodyInBox(StringBuffer buffer, dynamic body, int width,
      {int maxLines = 5}) {
    String bodyStr;
    if (body is Map || body is List) {
      try {
        final encoder = const JsonEncoder.withIndent('  ');
        bodyStr = encoder.convert(body);
      } catch (_) {
        bodyStr = body.toString();
      }
    } else {
      bodyStr = body.toString();
    }

    final lines = bodyStr.split('\n').take(maxLines).toList();
    for (final line in lines) {
      final displayLine = _truncate(line, width - 6);
      buffer.writeln(
          '$vertical     $displayLine${' ' * (width - displayLine.length - 5)}$vertical');
    }

    final totalLines = bodyStr.split('\n').length;
    if (totalLines > maxLines) {
      final moreLine = '... ${totalLines - maxLines} more lines';
      buffer.writeln(
          '$vertical     $moreLine${' ' * (width - moreLine.length - 5)}$vertical');
    }
  }
}
