import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// What the terminal shows when an expectation fails.
void main() {
  group('a failed expectation', () {
    test('is printed as its message, with no stack under it', () {
      final FlutterErrorDetails compact = compactFailureDetails(
        FlutterErrorDetails(
          exception: TestFailure('Expected: true\n  Actual: <false>'),
          stack: StackTrace.current,
          library: 'flutter test framework',
          informationCollector: () => <DiagnosticsNode>[
            DiagnosticsNode.message('the framework\'s own commentary'),
          ],
        ),
      );

      expect(compact.exception, isA<TestFailure>());
      expect(
        compact.stack,
        isNull,
        reason:
            'forty frames of async plumbing bury the one line worth '
            'reading',
      );
      expect(compact.informationCollector, isNull);
      expect(
        compact.toString(),
        contains('Actual: <false>'),
        reason: 'the message itself is the whole point of keeping it',
      );
    });
  });

  group('anything that is not an expectation', () {
    test('keeps its stack, which is all it has to say', () {
      final StackTrace stack = StackTrace.current;
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: RangeError.index(3, <int>[1, 2]),
        stack: stack,
        library: 'flutter test framework',
      );

      expect(
        compactFailureDetails(details),
        same(details),
        reason:
            'a bug in the suite says nothing without the frames that led '
            'there',
      );
    });
  });
}
