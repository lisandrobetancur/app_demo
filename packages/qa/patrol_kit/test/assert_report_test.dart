import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// Tests the seam between soft assertions and the report.
///
/// The two mechanisms are easy to wire together in a way that looks right and
/// silently isn't: a collector that still throws stops the checks after it, and
/// a report that only emits on failure leaves a green step looking like it
/// verified nothing. Both halves are pinned here.
///
/// Runs headless — no browser, no device.
void main() {
  /// Captures the marker lines a block prints.
  ///
  /// `debugPrintSynchronously` goes through `print`, so the zone sees it.
  List<String> markersFrom(void Function() body) {
    final List<String> lines = <String>[];
    runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, String line) => lines.add(line),
      ),
    );
    return lines
        .where((String line) => line.startsWith('PATROL_ASSERT '))
        .toList();
  }

  group('soft assertions reach the report', () {
    test('a passing check is reported, not just a failing one', () {
      final AssertD softly = AssertD();
      final List<String> markers = markersFrom(
        () => softly.softExpect(2, equals(2), reason: 'two equals two'),
      );

      expect(markers, hasLength(1));
      expect(markers.single, contains('"status":"passed"'));
      expect(markers.single, contains('two equals two'));
      expect(
        softly.hasFailures,
        isFalse,
        reason: 'a passing check must not be collected as a failure',
      );
    });

    test('a failing check is reported and collected, not thrown', () {
      final AssertD softly = AssertD();
      final List<String> markers = markersFrom(
        () => softly.softExpect(1, equals(2), reason: 'one equals two'),
      );

      expect(markers, hasLength(1));
      expect(markers.single, contains('"status":"failed"'));
      expect(
        softly.failureCount,
        1,
        reason: 'the failure must be collected for the step boundary to raise',
      );
    });

    test('the marker carries what was expected and what was found', () {
      final AssertD softly = AssertD();
      final List<String> markers = markersFrom(
        () => softly.softExpect(1, equals(2), reason: 'one equals two'),
      );

      expect(markers.single, contains('"expected"'));
      expect(markers.single, contains('"actual"'));
      expect(markers.single, contains('<2>'));
      expect(markers.single, contains('<1>'));
    });

    test('checks after a failure still run and still report', () {
      // The whole point of soft assertions: a hard expect on the first would
      // never let the second run, so the report would show one check where
      // three were written.
      final AssertD softly = AssertD();
      final List<String> markers = markersFrom(() {
        softly
          ..softExpect(1, equals(2), reason: 'first, fails')
          ..softExpect(2, equals(2), reason: 'second, passes')
          ..softExpect(3, equals(4), reason: 'third, fails');
      });

      expect(markers, hasLength(3));
      expect(softly.failureCount, 2);
    });
  });

  group('the step boundary', () {
    test('aggregates every collected failure into one', () {
      final AssertD softly = AssertD();
      runZoned(
        () {
          softly
            ..softExpect(1, equals(2), reason: 'first')
            ..softExpect(3, equals(4), reason: 'second');
        },
        zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
      );

      expect(
        softly.assertAll,
        throwsA(
          isA<TestFailure>().having(
            (TestFailure failure) => failure.message,
            'message',
            contains('Multiple Failures (2 failures)'),
          ),
        ),
      );
    });

    test('clears after raising, so the next step starts clean', () {
      final AssertD softly = AssertD();
      runZoned(
        () => softly.softExpect(1, equals(2), reason: 'first'),
        zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
      );

      expect(softly.assertAll, throwsA(isA<TestFailure>()));
      expect(
        softly.hasFailures,
        isFalse,
        reason: 'a stale failure would fail the following step instead',
      );
      expect(softly.assertAll, returnsNormally);
    });
  });
}
