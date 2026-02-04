/// ANSI color codes for terminal output.
///
/// Dragonfly uses a purple-based color scheme with Bootstrap-inspired
/// semantic colors for different log levels.
///
/// Uses basic ANSI codes for maximum compatibility with VSCode, Flutter,
/// and other terminals.
class DragonflyLogColors {
  DragonflyLogColors._();

  // Reset
  static const String reset = '\x1B[0m';

  // Text styles
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';

  // Framework primary colors (Purple/Magenta palette - using basic ANSI)
  static const String purple = '\x1B[35m';           // Magenta (purple)
  static const String purpleLight = '\x1B[95m';      // Bright Magenta
  static const String purpleDark = '\x1B[35m';       // Magenta
  static const String violet = '\x1B[95m';           // Bright Magenta
  static const String magenta = '\x1B[35m';          // Magenta

  // Bootstrap-inspired semantic colors (basic ANSI)
  static const String success = '\x1B[32m';          // Green
  static const String info = '\x1B[36m';             // Cyan
  static const String warning = '\x1B[33m';          // Yellow
  static const String danger = '\x1B[91m';           // Bright Red
  static const String error = '\x1B[31m';            // Red

  // Network specific colors
  static const String request = '\x1B[34m';          // Blue
  static const String response = '\x1B[92m';         // Bright Green

  // HTTP method colors
  static const String get = '\x1B[36m';              // Cyan
  static const String post = '\x1B[32m';             // Green
  static const String put = '\x1B[33m';              // Yellow
  static const String patch = '\x1B[33m';            // Yellow
  static const String delete = '\x1B[31m';           // Red

  // Status code colors
  static const String status2xx = '\x1B[32m';        // Green (success)
  static const String status3xx = '\x1B[36m';        // Cyan (redirect)
  static const String status4xx = '\x1B[33m';        // Yellow (client error)
  static const String status5xx = '\x1B[31m';        // Red (server error)

  // Text colors
  static const String white = '\x1B[97m';            // Bright White
  static const String gray = '\x1B[90m';             // Bright Black (Gray)
  static const String darkGray = '\x1B[90m';         // Bright Black (Gray)

  // Background colors
  static const String bgPurple = '\x1B[45m';         // Magenta background
  static const String bgSuccess = '\x1B[42m';        // Green background
  static const String bgInfo = '\x1B[46m';           // Cyan background
  static const String bgWarning = '\x1B[43m';        // Yellow background
  static const String bgDanger = '\x1B[41m';         // Red background

  /// Get color for HTTP method.
  static String forMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return get;
      case 'POST':
        return post;
      case 'PUT':
        return put;
      case 'PATCH':
        return patch;
      case 'DELETE':
        return delete;
      default:
        return purple;
    }
  }

  /// Get color for HTTP status code.
  static String forStatusCode(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return status2xx;
    if (statusCode >= 300 && statusCode < 400) return status3xx;
    if (statusCode >= 400 && statusCode < 500) return status4xx;
    if (statusCode >= 500) return status5xx;
    return gray;
  }
}
