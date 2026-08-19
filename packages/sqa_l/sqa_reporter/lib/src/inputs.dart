/// The input adapters: one per transport, both producing the same model.
///
/// The *transport* differs per platform while the payload does not — the same
/// port split the original converter chose, for the same reason:
///
///  * [parsePlaywright] — web. Playwright captures the browser console per
///    test and its JSON report is the only place those lines survive, so the
///    tests arrive already separated.
///  * [parsePatrolLog] — Android and iOS. The same markers arrive through the
///    device log (`adb logcat`, `os_log`), so the adapter has to find the
///    test boundaries itself, from the `type: "test"` entries in the stream.
///    The lines must come from the device log, not from `patrol test`'s
///    stdout: the CLI consumes `PATROL_LOG` to pretty-print it and silently
///    drops everything else, including our own markers.
library;

import 'dart:convert';
import 'dart:io';

import 'markers.dart';
import 'model.dart';

/// Playwright's status vocabulary → ours.
const Map<String, RunStatus> _playwrightStatus = <String, RunStatus>{
  'passed': RunStatus.passed,
  'failed': RunStatus.failed,
  'timedOut': RunStatus.broken,
  'interrupted': RunStatus.broken,
  'skipped': RunStatus.skipped,
};

/// `PATROL_LOG` test-entry status → ours.
const Map<String, RunStatus> _testEntryStatus = <String, RunStatus>{
  'success': RunStatus.passed,
  'failure': RunStatus.failed,
  'skip': RunStatus.skipped,
};

/// Web adapter: one case per Playwright result. Mostly a field rename, since
/// Playwright already separated the tests and captured each one's stdout.
///
/// [zone] is the clock a timestamp with no zone was written on — see
/// [epochOfStamp]. Playwright's own times carry `Z`, so it reaches only the
/// markers the browser printed.
ParsedRun parsePlaywright(File input, {Duration zone = Duration.zero}) {
  final Map<String, Object?> report =
      jsonDecode(input.readAsStringSync()) as Map<String, Object?>;
  final List<RunCase> cases = <RunCase>[];

  for (final Object? suite
      in (report['suites'] as List<Object?>?) ?? <Object?>[]) {
    final Map<String, Object?> suiteMap = suite! as Map<String, Object?>;
    for (final Object? spec
        in (suiteMap['specs'] as List<Object?>?) ?? <Object?>[]) {
      final Map<String, Object?> specMap = spec! as Map<String, Object?>;
      for (final Object? test
          in (specMap['tests'] as List<Object?>?) ?? <Object?>[]) {
        final Map<String, Object?> testMap = test! as Map<String, Object?>;
        for (final Object? result
            in (testMap['results'] as List<Object?>?) ?? <Object?>[]) {
          final Map<String, Object?> resultMap =
              result! as Map<String, Object?>;
          final ({String suite, String name}) title = splitTitle(
            '${specMap['title'] ?? ''}',
          );
          final int start =
              epochOfStamp('${resultMap['startTime']}', zone: zone) ?? 0;
          final ({String? message, String? trace}) failure = _failureFrom(
            resultMap['errors'] as List<Object?>?,
          );
          final String stdout = _stdoutOf(
            resultMap['stdout'] as List<Object?>?,
          );
          final MarkerParse parsed = parseMarkers(stdout, start, zone: zone);
          cases.add(
            RunCase(
              suite: title.suite,
              name: title.name,
              status:
                  _playwrightStatus['${resultMap['status']}'] ??
                  RunStatus.unknown,
              start: start,
              stop: start + ((resultMap['duration'] as num?) ?? 0).round(),
              thread: 'worker-${resultMap['workerIndex'] ?? 0}',
              retry: (resultMap['retry'] as num?)?.toInt() ?? 0,
              failureMessage: failure.message,
              failureTrace: failure.trace,
              steps: parsed.steps,
              orphanShots: parsed.orphanShots,
              meta: parsed.meta,
              params: parsed.params,
              tags: parsed.tags,
              logLines: parsed.logLines,
            ),
          );
        }
      }
    }
  }

  final Map<String, Object?>? stats = report['stats'] as Map<String, Object?>?;
  final Map<String, Object?>? config =
      report['config'] as Map<String, Object?>?;
  return ParsedRun(
    cases: cases,
    startedAt: stats?['startTime'] as String?,
    workers: (config?['workers'] as num?)?.toInt() ?? 1,
  );
}

/// Mobile adapter: one case per `type: "test"` pair in the device log. A
/// `start` entry opens a case and the next terminal entry closes it; every
/// line in between belongs to that test, and anything printed between tests
/// is device noise and is dropped.
///
/// [zone] matters more here than on the web path: a device log has no
/// real-UTC reference in it at all — the boundaries of every test are stamped
/// by the same naive device clock as the markers — so the clock the report is
/// drawn on is the only thing that says what those stamps mean. See
/// [epochOfStamp].
ParsedRun parsePatrolLog(File input, {Duration zone = Duration.zero}) {
  final List<RunCase> cases = <RunCase>[];
  _OpenCase? current;

  for (final String line in input.readAsLinesSync()) {
    final int at = line.indexOf('PATROL_LOG ');
    if (at >= 0) {
      Object? entry;
      try {
        entry = jsonDecode(
          stripAnsi(line.substring(at + 'PATROL_LOG '.length)),
        );
      } on FormatException {
        entry = null;
      }
      if (entry is Map<String, Object?> && entry['type'] == 'test') {
        final int when = epochOfStamp('${entry['timestamp']}', zone: zone) ?? 0;
        if (entry['status'] == 'start') {
          final ({String suite, String name}) title = splitTitle(
            stripAnsi('${entry['name'] ?? ''}'),
          );
          current = _OpenCase(
            suite: title.suite,
            name: title.name,
            start: when,
            zone: zone,
          );
        } else if (current != null) {
          final String? error = entry['error'] == null
              ? null
              : stripAnsi('${entry['error']}');
          cases.add(
            current.close(
              stop: when,
              status:
                  _testEntryStatus['${entry['status']}'] ?? RunStatus.unknown,
              error: error,
            ),
          );
          current = null;
        }
        continue;
      }
    }
    current?.lines.add(line);
  }

  // A case still open at the end means the process died mid-test.
  if (current != null) {
    cases.add(
      current.close(stop: current.start, status: RunStatus.broken, error: null),
    );
  }

  return ParsedRun(
    cases: cases,
    startedAt: cases.isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(
            cases.first.start,
            isUtc: true,
          ).toIso8601String()
        : null,
  );
}

/// Splits Patrol's spec title into the Dart file it came from and the test
/// name: `login_test logs in …` → (`login_test`, `logs in …`).
({String suite, String name}) splitTitle(String title) {
  final RegExpMatch? match = RegExp(r'^(\S+_test)\s+(.*)$').firstMatch(title);
  return match == null
      ? (suite: 'patrol', name: title)
      : (suite: match.group(1)!, name: match.group(2)!);
}

String _stdoutOf(List<Object?>? chunks) => (chunks ?? <Object?>[])
    .map(
      (Object? chunk) => chunk is String
          ? chunk
          : '${(chunk as Map<String, Object?>?)?['text'] ?? ''}',
    )
    .join();

({String? message, String? trace}) _failureFrom(List<Object?>? errors) {
  if (errors == null || errors.isEmpty) {
    return (message: null, trace: null);
  }
  final Map<String, Object?> first = errors.first! as Map<String, Object?>;
  final String message = stripAnsi(
    '${first['message'] ?? ''}',
  ).split('\n').take(4).join('\n').trim();
  final String trace = errors
      .map(
        (Object? error) => stripAnsi(
          '${(error! as Map<String, Object?>)['stack'] ?? (error as Map<String, Object?>)['message'] ?? ''}',
        ),
      )
      .join('\n\n')
      .trim();
  return (message: message, trace: trace);
}

class _OpenCase {
  _OpenCase({
    required this.suite,
    required this.name,
    required this.start,
    required this.zone,
  });

  final String suite;
  final String name;
  final int start;
  final Duration zone;
  final List<String> lines = <String>[];

  RunCase close({
    required int stop,
    required RunStatus status,
    required String? error,
  }) {
    final MarkerParse parsed = parseMarkers(
      lines.join('\n'),
      start,
      zone: zone,
    );
    return RunCase(
      suite: suite,
      name: name,
      status: status,
      start: start,
      stop: stop,
      thread: 'device',
      failureMessage: error?.split('\n').take(4).join('\n').trim(),
      failureTrace: error?.trim(),
      steps: parsed.steps,
      orphanShots: parsed.orphanShots,
      meta: parsed.meta,
      params: parsed.params,
      tags: parsed.tags,
      logLines: parsed.logLines,
    );
  }
}
