import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../support/assert_d.dart';
import '../support/screenshot.dart';

/// Marker the Allure converter reads to rebuild the business steps.
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
  Future<T> step<T>(String name, Future<T> Function() body) async {
    final int id = _sequence++;
    debugPrintSynchronously('$_marker|begin|$id|$name');
    try {
      final T result = await body();
      // Raise anything the step collected, before it is called passed. A soft
      // failure that never surfaced would leave a green step in the report
      // covering a broken expectation — the classic way soft assertions go
      // wrong. The throw lands in the catch below, so the failure still gets
      // its screenshot and its `failed` marker.
      softly.assertAll();
      await $.takeScreenshot(name);
      debugPrintSynchronously('$_marker|end|$id|passed');
      return result;
    } on Object {
      await $.takeScreenshot('$name (failed)');
      debugPrintSynchronously('$_marker|end|$id|failed');
      rethrow;
    }
  }

  /// Asserts [actual] against [matcher], softly, and makes the check visible
  /// in the report.
  ///
  /// The two halves matter together. Collecting the failure means the checks
  /// after this one still run, so a step reports every broken expectation
  /// rather than stopping at the first. Reporting the check means a reader
  /// sees which rules the step verified and what each one found — a green
  /// step that asserted four things no longer looks like one that asserted
  /// nothing.
  ///
  /// [what] names the rule in business terms ("the total adds up to
  /// subtotal - discount + VAT"), not the mechanics. It becomes both the
  /// entry in the report and the reason on the failure.
  ///
  /// Nothing throws here: [step] raises whatever was collected at its own
  /// boundary, so the step still fails, still screenshots and still reports
  /// as failed.
  void expectThat(String what, Object? actual, Matcher matcher) =>
      softly.softExpect(actual, matcher, reason: what);
}
