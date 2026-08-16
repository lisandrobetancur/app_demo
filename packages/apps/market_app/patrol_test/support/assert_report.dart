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
