import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The parser owns the edges of the marker stream, so the edges are what the
/// tests pin: ownership of a late screenshot chunk, the clock model, and what
/// happens to whatever is still open when a test dies.
void main() {
  group('the step tree', () {
    late MarkerParse parsed;

    setUp(() {
      parsed = parseMarkers(passingStdout(), 1000);
    });

    test('nests interactions and assertions under the open business step', () {
      expect(parsed.steps, hasLength(2)); // business step + warn leaf
      final StepNode business = parsed.steps.first;
      expect(business.kind, StepKind.business);
      expect(business.name, 'Log in as the demo user');
      expect(business.children, hasLength(2));
      expect(business.children[0].kind, StepKind.interaction);
      expect(business.children[1].kind, StepKind.assertion);
    });

    test('dates business steps by the run clock, not the parse clock', () {
      final StepNode business = parsed.steps.first;
      // Opened before any PATROL_LOG timestamp → the seed; closed after the
      // interaction moved the clock to 10:00:02.500Z.
      expect(business.start, 1000);
      expect(
        business.stop,
        DateTime.parse('2026-08-18T10:00:02.500Z').millisecondsSinceEpoch,
      );
    });

    test('a device on another timezone does not make the test hours long', () {
      // The real defect, from a published run: the suite pins the browser to
      // `--web-timezone=America/Bogota`, Patrol stamps its markers with the
      // browser's wall clock and no zone, and the generator read them as UTC.
      // Every step landed five hours before the test that produced it, and
      // widening the test to cover its steps stretched all six scenarios to
      // "5h 0m" against a run that took barely a minute.
      final int startUtc = DateTime.parse(
        '2026-08-19T01:10:36.000Z',
      ).millisecondsSinceEpoch;
      // What the browser printed at that instant: the same moment, five hours
      // earlier on the clock, with nothing saying so.
      const String naive = '2026-08-18T20:10:41.000';
      final MarkerParse shifted = parseMarkers('''
PATROL_STEP|begin|1|Log in as the demo user
PATROL_LOG {"type":"step","status":"start","action":"tap","timestamp":"$naive"}
PATROL_LOG {"type":"step","status":"success","action":"tap","timestamp":"2026-08-18T20:10:43.000"}
PATROL_STEP|end|1|passed
''', startUtc);

      final StepNode business = shifted.steps.single;
      expect(
        business.stop - business.start,
        lessThan(const Duration(minutes: 1).inMilliseconds),
        reason: 'seven seconds of tapping, not five hours',
      );
      expect(
        business.start,
        greaterThanOrEqualTo(startUtc),
        reason: 'a step cannot begin before the test it belongs to',
      );
      expect(
        business.children.single.start - startUtc,
        const Duration(seconds: 5).inMilliseconds,
        reason:
            'the real five seconds of waiting survive the correction; '
            'only the whole hours of timezone are taken out',
      );
    });

    test('an assertion is a leaf carrying expected and actual', () {
      final StepNode assertion = parsed.steps.first.children[1];
      expect(assertion.status, RunStatus.passed);
      expect(
        assertion.params.map((RunParam p) => p.name),
        containsAll(<String>['expected', 'actual']),
      );
    });

    test('a screenshot whose last chunk lands after the step closed still '
        'belongs to that step', () {
      final StepNode business = parsed.steps.first;
      expect(business.shots, hasLength(2));
      expect(business.shots.last.name, 'after_login');
      expect(business.shots.last.bytes, isNotEmpty);
      expect(parsed.orphanShots, isEmpty);
    });

    test('warn earns a leaf; info stays in the log only', () {
      expect(parsed.steps.last.kind, StepKind.logNote);
      expect(parsed.steps.last.status, RunStatus.skipped);
      expect(parsed.logLines, hasLength(2)); // info + warn both narrated
    });

    test('collects meta, params and tags for the test, not for a step', () {
      expect(parsed.meta?.epic, 'Access');
      expect(parsed.meta?.feature, 'Authentication');
      expect(parsed.params.single.name, 'User');
      expect(parsed.tags, <String>['smoke_test', 'success']);
    });
  });

  group('a timestamp Patrol wrote', () {
    const Duration bogota = Duration(hours: -5);
    final int noon = DateTime.utc(
      2026,
      8,
      18,
      15,
    ).millisecondsSinceEpoch; // 10:00 in Bogotá

    test('names an instant only once you say which clock it was on', () {
      expect(epochOfStamp('2026-08-18T10:00:00.000', zone: bogota), noon);
      expect(
        epochOfStamp('2026-08-18T10:00:00.000'),
        DateTime.utc(2026, 8, 18, 10).millisecondsSinceEpoch,
        reason: 'no zone given, none assumed: it reads as UTC',
      );
    });

    test('is left alone when it already carries one', () {
      // Playwright's `startTime` is this shape, and it is right as it stands.
      expect(epochOfStamp('2026-08-18T15:00:00.000Z', zone: bogota), noon);
      expect(epochOfStamp('2026-08-18T10:00:00.000-05:00', zone: bogota), noon);
    });

    test('reads the same on any machine, whatever its own zone is', () {
      // `DateTime.parse` would resolve a naive stamp against the local zone,
      // so the same log gave one answer on a CI runner in UTC and another on
      // a laptop in Bogotá. The suite proves this by running under
      // `TZ=America/Bogota` as well as under UTC.
      expect(
        epochOfStamp('2026-08-18T15:00:00.000'),
        DateTime.utc(2026, 8, 18, 15).millisecondsSinceEpoch,
      );
    });

    test('unreadable or absent leaves the clock where it was', () {
      expect(epochOfStamp(null), isNull);
      expect(epochOfStamp('  '), isNull);
      expect(epochOfStamp('null'), isNull);
    });
  });

  group('what a dying test leaves open', () {
    test('is marked broken, because that is what actually broke', () {
      final MarkerParse parsed = parseMarkers(brokenStdout(), 0);
      final StepNode business = parsed.steps.single;
      expect(business.status, RunStatus.broken);
      expect(business.children.single.status, RunStatus.broken);
    });

    test('promotes a transport "failed" with no failed step to broken', () {
      final MarkerParse parsed = parseMarkers(brokenStdout(), 0);
      expect(promoteStatus(RunStatus.failed, parsed.steps), RunStatus.broken);
    });

    test('does not promote when a real assertion failed', () {
      final MarkerParse parsed = parseMarkers(passingStdout(), 0);
      parsed.steps.first.children[1].status = RunStatus.failed;
      expect(promoteStatus(RunStatus.failed, parsed.steps), RunStatus.failed);
    });
  });
}
