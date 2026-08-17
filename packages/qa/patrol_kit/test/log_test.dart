import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// What the run log promises.
///
/// Two things, and they pull in opposite directions: a line has to survive
/// the trip out of a browser tab or a device log intact, and a line below the
/// threshold has to cost nothing. The first is why the payload is one-line
/// JSON; the second is why the threshold is checked before anything is built.
void main() {
  /// Captures the `PATROL_TRACE` lines a block prints.
  List<Map<String, Object?>> tracesFrom(void Function() body) {
    final List<String> lines = <String>[];
    runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, String line) => lines.add(line),
      ),
    );
    return lines
        .where((String line) => line.startsWith('PATROL_TRACE '))
        .map(
          (String line) =>
              jsonDecode(line.substring('PATROL_TRACE '.length))
                  as Map<String, Object?>,
        )
        .toList();
  }

  setUp(Log.reset);
  tearDown(Log.reset);

  test('a line carries its level, its time and its message', () {
    final List<Map<String, Object?>> traces = tracesFrom(
      () => Log.info('Comprando como ana@market.demo'),
    );

    expect(traces, hasLength(1));
    expect(traces.single['level'], 'info');
    expect(traces.single['message'], 'Comprando como ana@market.demo');
    expect(DateTime.tryParse(traces.single['at']! as String), isNotNull);
  });

  test('the threshold drops what is below it', () {
    Log.threshold = LogLevel.warn;

    final List<Map<String, Object?>> traces = tracesFrom(() {
      Log.trace('no');
      Log.debug('no');
      Log.info('no');
      Log.warn('sí');
      Log.error('sí');
    });

    expect(traces.map((Map<String, Object?> t) => t['level']), <String>[
      'warn',
      'error',
    ]);
  });

  test('the default lets info through and holds debug back', () {
    // The default matters: it is what a run uses when nobody passed
    // `--dart-define=E2E_LOG_LEVEL`, which is every run until one goes wrong.
    expect(Log.threshold, LogLevel.info);

    final List<Map<String, Object?>> traces = tracesFrom(() {
      Log.debug('detalle');
      Log.info('narración');
    });

    expect(traces.map((Map<String, Object?> t) => t['message']), <String>[
      'narración',
    ]);
  });

  test('a message with a newline stays one record', () {
    // The converter splits the stream on newlines. A raw multi-line message
    // would be read as a trace followed by a line of garbage, so the payload
    // is encoded rather than interpolated.
    final List<Map<String, Object?>> traces = tracesFrom(
      () => Log.error('falló\nen dos líneas'),
    );

    expect(traces, hasLength(1));
    expect(traces.single['message'], 'falló\nen dos líneas');
  });

  test('structured data travels alongside the message', () {
    final List<Map<String, Object?>> traces = tracesFrom(
      () => Log.info('Carrito', data: <String, Object>{'items': 3}),
    );

    expect(traces.single['data'], '{"items":3}');
  });

  test('data that cannot be encoded falls back rather than throwing', () {
    // A logger that can bring down a run by being handed an awkward object is
    // worse than no logger.
    final List<Map<String, Object?>> traces = tracesFrom(
      () => Log.info('objeto', data: Object()),
    );

    expect(traces, hasLength(1));
    expect(traces.single['data'], contains('Object'));
  });

  test('the buffered lines read as a log', () {
    tracesFrom(() {
      Log.info('primero');
      Log.warn('segundo');
    });

    expect(Log.emitted, hasLength(2));
    expect(Log.emitted.first, contains('[INFO] primero'));
    expect(Log.emitted.last, contains('[WARN] segundo'));
  });
}
