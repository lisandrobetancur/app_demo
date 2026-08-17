import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Run log for the suite.
///
/// Separate from the assertions on purpose. An assertion is a claim about the
/// product and belongs in the report as a verdict; a log line is the trail
/// that explains *how* the test got there — which account it picked, which
/// row of a data set it was on, what it decided to skip. When a run fails at
/// three in the morning, the verdict says what broke and the log says under
/// what circumstances.
///
/// Lines travel as the `PATROL_TRACE` marker on stdout, the same channel the
/// steps and screenshots already use, and the Allure converter turns them
/// into a `run.log` attachment on the test. `warn` and `error` are *also*
/// rendered as leaf steps in the tree, because a warning nobody opens the
/// attachment to read is a warning that did not happen.
///
/// Not to be confused with Patrol's own `PATROL_LOG`, which carries its
/// interactions (tap, enterText) and is parsed separately.
enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error;

  /// Ordering for the threshold comparison. `trace` is the noisiest.
  bool operator >=(LogLevel other) => index >= other.index;
}

/// Marker the Allure converter reads to rebuild the run log.
const String _marker = 'PATROL_TRACE';

/// The suite's logger.
///
/// ```dart
/// Log.info('Comprando como ${user.email}');
/// Log.debug('Carrito', data: {'items': 3, 'total': 71400});
/// Log.warn('El cupón ya estaba aplicado, no se vuelve a aplicar');
/// ```
class Log {
  const Log._();

  /// Lines below this level are dropped before they are printed.
  ///
  /// Defaults to what `--dart-define=E2E_LOG_LEVEL=…` says, and to
  /// [LogLevel.info] when nothing says anything. A debug run is therefore a
  /// flag on the command line rather than an edit to a test:
  ///
  /// ```sh
  /// patrol test --device chrome --dart-define=E2E_LOG_LEVEL=debug
  /// ```
  static LogLevel threshold = _thresholdFromEnvironment();

  /// Every line emitted so far, newest last. Kept for tests of the kit.
  static final List<String> _emitted = <String>[];

  /// The lines this run has produced, formatted as they were printed.
  static List<String> get emitted => List<String>.unmodifiable(_emitted);

  /// Forgets the buffered lines and restores the configured threshold.
  static void reset() {
    _emitted.clear();
    threshold = _thresholdFromEnvironment();
  }

  /// Framework-level detail: what the kit itself did.
  static void trace(String message, {Object? data}) =>
      _write(LogLevel.trace, message, data);

  /// Detail worth having when something is being diagnosed.
  static void debug(String message, {Object? data}) =>
      _write(LogLevel.debug, message, data);

  /// The narration of the run, at the level a reader follows.
  static void info(String message, {Object? data}) =>
      _write(LogLevel.info, message, data);

  /// Something surprising that did not stop the test.
  ///
  /// Surfaces in the report as its own step, so it is visible without
  /// opening the attachment.
  static void warn(String message, {Object? data}) =>
      _write(LogLevel.warn, message, data);

  /// Something that went wrong, whether or not the test recovered.
  static void error(String message, {Object? data}) =>
      _write(LogLevel.error, message, data);

  static void _write(LogLevel level, String message, Object? data) {
    if (!(level >= threshold)) {
      return;
    }

    final Map<String, String> payload = <String, String>{
      'level': level.name,
      'at': DateTime.now().toIso8601String(),
      'message': message,
      if (data != null) 'data': _describe(data),
    };

    _emitted.add(
      '${payload['at']} [${level.name.toUpperCase()}] $message'
      '${data == null ? '' : ' ${payload['data']}'}',
    );

    // One-line JSON, so a message containing a newline or a `|` cannot be
    // read as two records — and `debugPrintSynchronously` rather than
    // `debugPrint`, which throttles to about a kilobyte a second and drops
    // the rest without saying so.
    debugPrintSynchronously('$_marker ${jsonEncode(payload)}');
  }

  /// Renders [data] compactly, falling back to `toString` for anything
  /// `jsonEncode` refuses — a log line is never worth throwing over.
  static String _describe(Object data) {
    try {
      return jsonEncode(data);
    } on Object {
      return data.toString();
    }
  }

  static LogLevel _thresholdFromEnvironment() {
    const String configured = String.fromEnvironment(
      'E2E_LOG_LEVEL',
      defaultValue: 'info',
    );
    for (final LogLevel level in LogLevel.values) {
      if (level.name == configured.trim().toLowerCase()) {
        return level;
      }
    }
    return LogLevel.info;
  }
}
