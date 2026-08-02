import 'package:logger/logger.dart';

/// Workspace-wide logger. `print` is banned by the analyzer; every package
/// logs through [log] instead.
class AppLogger {
  AppLogger()
    : _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          colors: false,
          printEmojis: false,
        ),
      );

  final Logger _logger;

  void debug(String message) => _logger.d(message);

  void info(String message) => _logger.i(message);

  void warning(String message) => _logger.w(message);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

/// Single shared instance used across the workspace.
final AppLogger log = AppLogger();
