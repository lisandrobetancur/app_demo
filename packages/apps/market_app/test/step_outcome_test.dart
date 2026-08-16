import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../patrol_test/support/assert_report.dart';

/// Pins which errors are the product's fault and which are the suite's.
///
/// The rule decides what a reader sees in the report: *failed* means the app
/// misbehaved and someone should look at it; *broken* means the test could not
/// check at all and someone should fix the test. Getting it backwards is worse
/// than not classifying — it sends people to the wrong place.
///
/// The cases below use the errors the suite actually produces, not invented
/// ones, so the classification is tied to real behaviour rather than to an
/// assumption about it.
void main() {
  group('an unmet expectation is the product misbehaving', () {
    test('a failed expect raises TestFailure → failed', () {
      Object? raised;
      try {
        expect(1, equals(2), reason: 'uno es dos');
      } on Object catch (error) {
        raised = error;
      }

      expect(raised, isA<TestFailure>());
      expect(stepOutcomeOf(raised!), 'failed');
    });

    test('an aggregate of several is still failed', () {
      expect(
        stepOutcomeOf(TestFailure('Multiple Failures (2 failures)')),
        'failed',
      );
    });
  });

  group('anything else is the test unable to do its job', () {
    testWidgets('a locator that matched nothing → broken', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('hola'))),
      );

      Object? raised;
      try {
        // The real failure mode: reading a widget the finder never found.
        tester.widget<Text>(find.byKey(const Key('no_existe')));
      } on Object catch (error) {
        raised = error;
      }

      expect(raised, isA<StateError>());
      expect(stepOutcomeOf(raised!), 'broken');
    });

    test('an unreadable value → broken', () {
      // What `UiElement.text` and `Money.parse` raise when the locator points
      // at the wrong thing.
      expect(stepOutcomeOf(StateError('Sin texto en key ...')), 'broken');
      expect(stepOutcomeOf(const FormatException('No number in ""')), 'broken');
    });

    test('a wait that timed out → broken', () {
      // Patrol's timeout is not a TestFailure, which is exactly why the rule
      // keys off the type rather than off "did something throw".
      expect(stepOutcomeOf(TimeoutException()), 'broken');
    });
  });
}

/// Stand-in for Patrol's timeout, which cannot be constructed outside a live
/// Patrol run. Only its type matters to the rule.
class TimeoutException implements Exception {
  @override
  String toString() => 'PatrolTimeoutException: waited too long';
}
