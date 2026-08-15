import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../support/screenshot.dart';

/// Marker the Allure converter reads to rebuild the business steps.
const String _marker = 'PATROL_STEP';

/// Marker carrying one assertion and its outcome.
const String _assertMarker = 'PATROL_ASSERT';

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
      await $.takeScreenshot(name);
      debugPrintSynchronously('$_marker|end|$id|passed');
      return result;
    } on Object {
      await $.takeScreenshot('$name (failed)');
      debugPrintSynchronously('$_marker|end|$id|failed');
      rethrow;
    }
  }

  /// Asserts [actual] against [matcher] and makes the check visible in the
  /// report.
  ///
  /// `expect` alone leaves nothing behind: a passing assertion is invisible,
  /// and a failing one only surfaces as the test's error message. The reader
  /// of a report cannot tell whether a green step verified four things or
  /// none. This wrapper emits every check as its own entry under the step,
  /// carrying what was expected and what was found — so a green step shows
  /// its evidence, and a red one shows which check broke while the rest
  /// still read as passed.
  ///
  /// [what] names the rule in business terms ("the total adds up to
  /// subtotal - discount + VAT"), not the mechanics.
  ///
  /// The assertion itself still runs through `expect`, so the failure
  /// behaviour, the message and the stack trace are unchanged.
  void expectThat(String what, Object? actual, Matcher matcher) {
    final bool passed = matcher.matches(actual, <Object?, Object?>{});
    final Map<String, String> payload = <String, String>{
      'name': what,
      'status': passed ? 'passed' : 'failed',
      // The matcher's own words, so the report reads the same as a failure
      // message would ("a numeric value within <1.0> of <66937500.0>").
      'expected': matcher.describe(StringDescription()).toString(),
      'actual': (StringDescription()..addDescriptionOf(actual)).toString(),
    };
    debugPrintSynchronously('$_assertMarker ${jsonEncode(payload)}');

    expect(actual, matcher, reason: what);
  }
}
