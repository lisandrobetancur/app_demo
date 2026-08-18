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
