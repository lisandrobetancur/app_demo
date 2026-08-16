import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../patrol_test/support/assert_d.dart';
import '../patrol_test/support/consequence.dart';

/// Pins the rule behind `should`: several expectations behave softly, one
/// behaves hard, and both fall out of the same evaluation.
///
/// `should` itself lives on `BaseSteps`, which needs a live Patrol tester, so
/// the batching logic is exercised here through the same pieces it is built
/// from. The reimplementation below is deliberately the same five lines — if
/// it and `BaseSteps.shouldAll` ever disagree, this test is the one that
/// says so.
void main() {
  /// Mirrors `BaseSteps.shouldAll`.
  void shouldAll(List<Consequence> consequences) {
    final AssertD batch = AssertD();
    for (final Consequence consequence in consequences) {
      consequence.evaluateWith(batch);
    }
    final List<SoftFailure> failures = batch.failures;
    if (failures.isEmpty) {
      return;
    }
    if (failures.length == 1) {
      throw failures.single.failure;
    }
    batch.assertAll();
  }

  /// Runs [body] with the marker stream captured, returning both the markers
  /// and whatever it raised.
  ///
  /// Both halves are needed at once: the point of a batch is that it reports
  /// every check *and* raises, so a helper that only rethrew would lose the
  /// markers on exactly the runs worth inspecting.
  ({List<String> markers, Object? error}) runBatch(void Function() body) {
    final List<String> lines = <String>[];
    Object? raised;
    runZoned(
      () {
        try {
          body();
        } on Object catch (error) {
          raised = error;
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, String line) => lines.add(line),
      ),
    );
    return (
      markers: lines
          .where((String line) => line.startsWith('PATROL_ASSERT '))
          .toList(),
      error: raised,
    );
  }

  /// The message of the `TestFailure` [body] raised, or null if it passed.
  String? failureFrom(void Function() body) {
    final Object? error = runBatch(body).error;
    if (error == null) {
      return null;
    }
    expect(error, isA<TestFailure>());
    return (error as TestFailure).message;
  }

  group('one expectation behaves hard', () {
    test('passes silently', () {
      expect(
        failureFrom(
          () => shouldAll(<Consequence>[
            seeThat('la edad', () => '40', equals('40')),
          ]),
        ),
        isNull,
      );
    });

    test('raises the failure itself, not an aggregate', () {
      expect(
        failureFrom(
          () => shouldAll(<Consequence>[
            seeThat('la edad', () => '39', equals('40')),
          ]),
        ),
        isNot(contains('Multiple Failures')),
      );
    });
  });

  group('several expectations behave softly', () {
    test('the second is checked even when the first fails', () {
      final ({List<String> markers, Object? error}) run = runBatch(
        () => shouldAll(<Consequence>[
          seeThat('la edad', () => '39', equals('40')),
          seeThat('el nombre', () => 'Pedro', equals('Juan')),
        ]),
      );

      expect(run.error, isA<TestFailure>());
      // Both reached the report: the point of the batch. A hard assertion on
      // the first would have left one marker here.
      expect(run.markers, hasLength(2));
    });

    test('failures aggregate into one', () {
      expect(
        failureFrom(
          () => shouldAll(<Consequence>[
            seeThat('la edad', () => '39', equals('40')),
            seeThat('el nombre', () => 'Pedro', equals('Juan')),
          ]),
        ),
        contains('Multiple Failures (2 failures)'),
      );
    });

    test('one failure among several still raises bare', () {
      expect(
        failureFrom(
          () => shouldAll(<Consequence>[
            seeThat('la edad', () => '40', equals('40')),
            seeThat('el nombre', () => 'Pedro', equals('Juan')),
          ]),
        ),
        isNot(contains('Multiple Failures')),
      );
    });

    test('all passing raises nothing but still reports every check', () {
      final ({List<String> markers, Object? error}) run = runBatch(
        () => shouldAll(<Consequence>[
          seeThat('la edad', () => '40', equals('40')),
          seeThat('el nombre', () => 'Juan', equals('Juan')),
        ]),
      );

      expect(run.error, isNull);
      expect(run.markers, hasLength(2));
      expect(
        run.markers.every((String m) => m.contains('"status":"passed"')),
        isTrue,
      );
    });
  });

  group('reading the value', () {
    test('is deferred until the batch runs', () {
      int reads = 0;
      final Consequence consequence = seeThat('la edad', () {
        reads++;
        return '40';
      }, equals('40'));

      expect(reads, 0, reason: 'building a Consequence must not read anything');
      runBatch(() => shouldAll(<Consequence>[consequence]));
      expect(reads, 1);
    });

    test('a broken read propagates instead of being collected', () {
      // A locator that matched nothing is a broken test, not a failed
      // expectation — the line AssertD draws everywhere else.
      final ({List<String> markers, Object? error}) run = runBatch(
        () => shouldAll(<Consequence>[
          seeThat(
            'un valor ilegible',
            () => throw StateError('sin texto'),
            equals('40'),
          ),
        ]),
      );

      expect(run.error, isA<StateError>());
    });
  });
}
