import 'dart:developer' as developer;

/// A simple logging service to print formatted logs with different severity levels.
///
/// This service uses ANSI escape codes to colorize console output, making logs more
/// readable. It also formats logs with a border for better visibility.
abstract class LoggerHelper {
  /// Logs an informational message.
  ///
  /// - [message]: The main log message.
  /// - [details]: (Optional) Additional details related to the log.
  static void info(String message, [dynamic details]) {
    _log(message, details, "INFO", "\x1B[34m"); // Blue color
  }

  /// Logs a warning message.
  ///
  /// - [message]: The main warning message.
  /// - [details]: (Optional) Additional details related to the warning.
  static void warning(String message, [dynamic details]) {
    _log(message, details, "WARNING", "\x1B[33m"); // Yellow color
  }

  /// Logs an error message.
  ///
  /// - [message]: The error description.
  /// - [details]: (Optional) Additional details about the error.
  static void error(String message, [dynamic details]) {
    _log(message, details, "ERROR", "\x1B[31m"); // Red color
  }

  /// Internal method to format and log messages.
  ///
  /// - [message]: The log message.
  /// - [details]: (Optional) Additional details.
  /// - [level]: The log level (INFO, WARNING, ERROR).
  /// - [color]: ANSI color code for the log output.
  static void _log(String message, dynamic details, String level, String color) {
    final border = "═" * 50;
    final topBorder = "╔$border";
    final bottomBorder = "╚$border";
    final formattedLevel = "║ $level:";
    final formattedMessage = message;
    final formattedDetails = details != null ? "║ Details: $details" : "";

    final logOutput = """
$color$topBorder
$formattedLevel $formattedMessage
${details != null ? formattedDetails : ""}
$bottomBorder\x1B[0m
""";

    /// Uses `dart:developer` to log messages in a structured format.
    developer.log(logOutput);
  }
}
