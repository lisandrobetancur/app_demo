import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'assert_d.dart';
import 'assert_report.dart';
import 'consequence.dart';
import 'log.dart';
import 'screenshot.dart';

/// Marker the report generator reads to rebuild the business steps.
const String _marker = 'PATROL_STEP';

/// Base of every steps class.
///
/// A business step is the unit a reader cares about — "log in as the demo
/// user", "apply a valid coupon" — so it is also the unit worth a picture.
/// [step] delimits one, captures the frame it left on screen, and reports its
/// outcome, which lets the report nest Patrol's raw interactions underneath
/// and hang the screenshot on the step rather than on an individual tap.
abstract class BaseSteps {
  BaseSteps(this.$);

  final PatrolIntegrationTester $;

  /// Soft assertions collected while a step runs.
  ///
  /// The business step is the scope: everything a step checks is gathered
  /// here and raised together when it ends, so one broken expectation no
  /// longer hides the ones after it. "Soft" is about how far a failure
  /// travels, not about whether it counts — the step still fails, still
  /// screenshots, and still reports as failed.
  final AssertD softly = AssertD();

  static int _sequence = 0;

  /// Runs [body] as a named business step.
  ///
  /// The screenshot is taken after [body] settles, so the image shows the
  /// state the step produced. A failing step still emits its `end` marker
  /// (and its screenshot) before the error propagates, so the report shows
  /// what the screen looked like when it broke.
  ///
  /// A step that ends badly is reported as **failed** or **broken**, never
  /// just "red" — see [stepOutcomeOf].
  Future<T> step<T>(String name, Future<T> Function() body) async {
    final int id = _sequence++;
    debugPrintSynchronously('$_marker|begin|$id|$name');
    Log.debug('Step ▸ $name');
    try {
      final T result = await body();
      // Raise anything the step collected, before it is called passed. A soft
      // failure that never surfaced would leave a green step in the report
      // covering a broken expectation — the classic way soft assertions go
      // wrong. The throw lands in the catch below, so the failure still gets
      // its screenshot and its outcome marker.
      softly.assertAll();
      await $.takeScreenshot(name);
      debugPrintSynchronously('$_marker|end|$id|passed');
      return result;
    } on Object catch (error) {
      final String outcome = stepOutcomeOf(error);
      // At `error` and not `debug`: this is the line a reader looks for
      // first, and `broken` versus `failed` is the difference between "the
      // product is wrong" and "the test could not tell".
      Log.error('Step ✗ $name ($outcome)', data: '$error'.split('\n').first);
      await $.takeScreenshot('$name ($outcome)');
      debugPrintSynchronously('$_marker|end|$id|$outcome');
      rethrow;
    }
  }

  /// Checks one or more expectations together.
  ///
  /// ```dart
  /// should(
  ///   seeThat('la edad', () => ageField.text, equals('40')),
  ///   seeThat('the name', () => nameField.text, equals('Jane')),
  /// );
  /// ```
  ///
  /// **Several expectations behave softly, one behaves hard — and that falls
  /// out of a single rule** rather than two code paths: everything passed in
  /// is evaluated, failures are gathered, and whatever was gathered is raised
  /// when the call ends. With one expectation there is nothing after it to
  /// run, so raising at the end of the call is the same instant a hard
  /// assertion would have raised. With several, the second is checked even
  /// when the first fails, and the report shows both.
  ///
  /// A lone failure is rethrown as itself, not dressed up as an aggregate, so
  /// a single expectation reads exactly like a plain `expect`.
  ///
  /// Grouping is therefore the only thing that decides the behaviour, and it
  /// reads as intent: expectations written in one call are one claim, and a
  /// claim is checked whole. Split them into separate calls and each becomes
  /// a precondition for the next.
  ///
  /// This is the single way a step asserts. [softly] still exists underneath
  /// — [step] raises whatever it holds at the step boundary — but a step
  /// should not reach for it directly.
  void should(
    Consequence first, [
    Consequence? second,
    Consequence? third,
    Consequence? fourth,
    Consequence? fifth,
    Consequence? sixth,
    Consequence? seventh,
    Consequence? eighth,
  ]) => shouldAll(<Consequence>[
    first,
    if (second != null) second,
    if (third != null) third,
    if (fourth != null) fourth,
    if (fifth != null) fifth,
    if (sixth != null) sixth,
    if (seventh != null) seventh,
    if (eighth != null) eighth,
  ]);

  /// [should] over a list built at run time — one expectation per row, per
  /// field, per seeded record.
  void shouldAll(List<Consequence> consequences) {
    // Its own collector, not the step's: these expectations are a batch that
    // resolves here, which is what makes a single one behave hard.
    final AssertD batch = AssertD();
    for (final Consequence consequence in consequences) {
      consequence.evaluateWith(batch);
    }

    final List<SoftFailure> failures = batch.failures;
    if (failures.isEmpty) {
      return;
    }
    if (failures.length == 1) {
      // Rethrown bare: "Multiple Failures (1 failure)" around a lone
      // expectation would only obscure it. The batch is local, so nothing
      // outlives this call.
      throw failures.single.failure;
    }
    batch.assertAll();
  }
}
