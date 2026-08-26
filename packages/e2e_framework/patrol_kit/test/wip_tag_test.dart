// `flutter_test` re-exports `test_api`, which has a `Tags` of its own — an
// annotation for the test runner, unrelated to ours. Hidden here rather than
// prefixing every use, because in this file `Tags` means one thing.
import 'package:flutter_test/flutter_test.dart' hide Tags;
import 'package:patrol_kit/patrol_kit.dart';

/// What `Tags.wip` does to a test, decided where it has to be decided: at
/// registration, before any body runs.
///
/// The rule is small and the cost of getting it wrong is not. Skip too eagerly
/// and a suite goes quietly green while it verifies nothing; skip too late and
/// a half-written test fails a pipeline nobody wanted red.
void main() {
  group('a test tagged wip', () {
    test('is registered as skipped on an ordinary run', () {
      expect(skipFor(<String>[Tags.wip]), isTrue);
      expect(skipFor(<String>[Tags.smoke, Tags.wip]), isTrue);
    });

    test('runs when the run asked for exactly those', () {
      expect(skipFor(<String>[Tags.wip], wipRun: true), isNull);
    });
  });

  group('a test not tagged wip', () {
    test('is left alone, and null is what "run it" looks like', () {
      // Not `false`: `patrolTest` reads an answer, and null is the absence of
      // one. False would still be an author saying something.
      expect(skipFor(<String>[Tags.smoke, Tags.success]), isNull);
      expect(skipFor(<String>[]), isNull);
      expect(skipFor(<String>[Tags.regression], wipRun: true), isNull);
    });
  });

  group('an explicit skip', () {
    test('wins over the tag, in both directions', () {
      // A test that says why it is skipped knows better than a tag — and a
      // `skip: false` beside a wip tag is somebody deliberately running one.
      expect(skipFor(<String>[Tags.smoke], explicit: true), isTrue);
      expect(skipFor(<String>[Tags.wip], explicit: false), isFalse);
    });
  });
}
