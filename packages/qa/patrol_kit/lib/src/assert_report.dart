import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Marker carrying one assertion and its outcome to the Allure converter.
const String assertMarker = 'PATROL_ASSERT';

/// Reports one assertion, passed or failed.
///
/// Soft assertions and a readable report solve different halves of the same
/// problem, and each is worth little without the other:
///
///  * collecting failures means a step reports *every* broken expectation
///    instead of stopping at the first — but the aggregated `TestFailure` is
///    a wall of text at the end of a run;
///  * reporting every check means the reader sees which rules a step
///    verified and what each one found — but a hard `expect` aborts the step,
///    so the checks after the first failure never run and never report.
///
/// So every soft assertion passes through here on its way to being collected.
/// The converter turns each one into a leaf step under the business step that
/// made it, and a step that failed three checks shows all three.
///
/// This prints and nothing more: it never throws, never decides an outcome,
/// and does not touch the app. A missing marker is a worse report, not a
/// wrong result.
void reportAssertion({
  required String name,
  required bool passed,
  String? expected,
  String? actual,
}) {
  final Map<String, String> payload = <String, String>{
    'name': name,
    'status': passed ? 'passed' : 'failed',
    if (expected != null) 'expected': expected,
    if (actual != null) 'actual': actual,
  };
  // One-line JSON, like Patrol's own `PATROL_LOG`, so a value containing the
  // field separator cannot corrupt the stream.
  debugPrintSynchronously('$assertMarker ${jsonEncode(payload)}');
}

/// Renders a matcher's expectation the way a failure message would
/// ("a numeric value within <1.0> of <66937500.0>").
String describeExpectation(Object? matcher) {
  if (matcher is Matcher) {
    return matcher.describe(StringDescription()).toString();
  }
  return '$matcher';
}

/// Renders a value the way a failure message would.
String describeValue(Object? value) =>
    (StringDescription()..addDescriptionOf(value)).toString();

/// Whether an error that ended a step is the product's fault or the test's.
///
/// The same line AssertD draws internally, carried out to the report:
///
///  * a [TestFailure] means an expectation the test *made* went unmet — the
///    test ran correctly and the product did not behave. `failed`.
///  * anything else means the test could not do its job: a locator that
///    matched nothing, a wait that timed out, a value that could not be read.
///    The product may be fine; nobody checked. `broken`.
///
/// It is the distinction WebDriver suites live by — an assertion failure
/// versus a `NoSuchElementException` — and the one Allure reports as *failed*
/// versus *broken*, so a reader can tell "the app is wrong" from "the suite
/// needs fixing" without opening a stack trace.
///
/// Decided on the error object, where the type is still known, rather than by
/// pattern-matching a message downstream: a message is not a contract.
String stepOutcomeOf(Object error) =>
    error is TestFailure ? 'failed' : 'broken';
