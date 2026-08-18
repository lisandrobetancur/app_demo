import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

bool _installed = false;

/// How a failed expectation is printed to the terminal.
///
/// By default the test framework dumps the exception *and* the stack that
/// reached it. For a failed assertion that stack is forty lines of the async
/// machinery — `_rootRunUnary`, `_propagateToListeners`, `handleValueCallback`
/// — through which the only two frames of ours are `should` and `shouldAll`,
/// which are the same two frames on every failure this suite can produce. It
/// buries the one thing worth reading:
///
/// ```
/// The following TestFailure was thrown running a test:
/// Expected: true
///   Actual: <false>
/// live validation blocks submission for "not-an-email"
/// ```
///
/// So a `TestFailure` — an expectation the test made and the product did not
/// meet — is printed as itself, message and nothing else. The test's own name
/// is already on the line above it, printed by the runner.
///
/// Anything that is *not* a `TestFailure` keeps its stack, and that asymmetry
/// is the whole point. A failed expectation says what went wrong in its
/// message; a `RangeError` from inside a page object says nothing without the
/// frames that led there, and that is a defect in the suite rather than in the
/// product.
///
/// Installs the compact reporter, once per process.
///
/// Called from `e2eTest` while the tests are being *registered*, not while one
/// is running: the framework asserts that a test body leaves
/// `reportTestException` as it found it, so a test that installed its own
/// reporter would fail on that check alone.
void useCompactFailureReports() {
  if (_installed) {
    return;
  }
  _installed = true;

  final TestExceptionReporter report = reportTestException;
  reportTestException = (FlutterErrorDetails details, String testDescription) =>
      report(compactFailureDetails(details), testDescription);
}

/// What the reporter above prints, as a value rather than an effect.
///
/// A `TestFailure` comes back stripped of the stack and of the framework's own
/// commentary — dropping those fields is what stops them being printed —
/// while anything else is returned untouched. Nothing here decides whether a
/// test passes: the same reporter is called either way, with the same
/// exception in it.
FlutterErrorDetails compactFailureDetails(FlutterErrorDetails details) =>
    details.exception is! TestFailure
    ? details
    : FlutterErrorDetails(
        exception: details.exception,
        library: details.library,
        silent: details.silent,
      );
