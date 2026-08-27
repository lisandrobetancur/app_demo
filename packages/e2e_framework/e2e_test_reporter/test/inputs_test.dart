import 'dart:io';

import 'package:e2e_test_reporter/e2e_test_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The transports differ; the model must not. Both adapters are fed the same
/// markers and must land in the same place.
void main() {
  late Directory tmp;

  setUpAll(() => tmp = Directory.systemTemp.createTempSync('reporter_inputs'));
  tearDownAll(() => tmp.deleteSync(recursive: true));

  group('the Playwright adapter', () {
    late ParsedRun run;

    setUpAll(() {
      final File input = File('${tmp.path}/results.json')
        ..writeAsStringSync(playwrightReport());
      run = parsePlaywright(input);
    });

    test('separates the cases the report already separated', () {
      expect(run.cases, hasLength(2));
      expect(run.cases.first.suite, 'login_test');
      expect(run.cases.first.name, 'logs in with the seeded demo account');
      expect(run.cases.first.status, RunStatus.passed);
      expect(run.cases.last.status, RunStatus.failed);
    });

    test('carries the run-level facts', () {
      expect(run.startedAt, '2026-08-18T10:00:00.000Z');
      expect(run.workers, 1);
    });

    test('keeps the failure message and the trace apart', () {
      final RunCase failing = run.cases.last;
      expect(failing.failureMessage, startsWith('StateError:'));
      expect(failing.failureTrace, contains('element.dart:68'));
    });
  });

  group('the device-log adapter', () {
    late ParsedRun run;

    setUpAll(() {
      final File input = File('${tmp.path}/device.log')
        ..writeAsStringSync(patrolLog());
      run = parsePatrolLog(input);
    });

    test('finds the test boundaries itself and drops device noise', () {
      expect(run.cases, hasLength(1));
      final RunCase testCase = run.cases.single;
      expect(testCase.suite, 'login_test');
      expect(testCase.status, RunStatus.passed);
      expect(testCase.thread, 'device');
      // The noise lines around the boundaries reached no step and no log.
      expect(testCase.logLines.join(), isNot(contains('device noise')));
    });

    test('parses the same markers into the same tree as the web path', () {
      final RunCase testCase = run.cases.single;
      expect(testCase.steps.first.name, 'Log in as the demo user');
      expect(testCase.steps.first.shots, hasLength(2));
      expect(testCase.meta?.feature, 'Authentication');
    });

    test('reads a stamp with no zone on the clock the report is drawn on', () {
      const Duration bogota = Duration(hours: -5);
      final File input = File('${tmp.path}/zoned.log')
        ..writeAsStringSync(patrolLog());
      final RunCase onDeviceClock = parsePatrolLog(
        input,
        zone: bogota,
      ).cases.single;

      String shown(int epoch) => timestampOf(
        DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true),
        offset: bogota,
      );

      // The device printed 10:00:00.500 and said nothing about where it was.
      // A device log holds no other clock to check it against — unlike the web
      // path, its test boundaries are stamped by the device too — so the
      // report's own clock is what the stamp means, and reading it back there
      // shows the hour the tester watched go by.
      expect(shown(onDeviceClock.start), '2026-08-18 10:00:00 UTC-5');
      expect(
        shown(run.cases.single.start),
        '2026-08-18 05:00:00 UTC-5',
        reason: 'read as UTC and printed at UTC-5, the same log loses 5 hours',
      );
      expect(
        onDeviceClock.stop - onDeviceClock.start,
        run.cases.single.stop - run.cases.single.start,
        reason: 'moving both ends of a test cannot change how long it took',
      );
    });

    test('a case still open at the end reads as broken', () {
      final File input = File('${tmp.path}/dead.log')
        ..writeAsStringSync(
          'PATROL_LOG {"type":"test","status":"start",'
          '"name":"cart_test pays","timestamp":"2026-08-18T10:02:00.000Z"}\n'
          '${brokenStdout()}',
        );
      final ParsedRun dead = parsePatrolLog(input);
      expect(dead.cases.single.status, RunStatus.broken);
    });
  });
}
