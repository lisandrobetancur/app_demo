import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// When a step captures the screen, and when it stays out of the way.
void main() {
  group('the default', () {
    test('captures a step that behaved and one that broke', () {
      expect(Capture.auto.capturesOnSuccess, isTrue);
      expect(Capture.auto.capturesOnFailure, isTrue);
    });
  });

  group('a step that says nothing while it behaves', () {
    test('still gets its picture when it breaks', () {
      expect(Capture.onFailure.capturesOnSuccess, isFalse);
      expect(
        Capture.onFailure.capturesOnFailure,
        isTrue,
        reason: 'a failure with no picture is the case screenshots exist for',
      );
    });
  });

  group('a step that captures by hand', () {
    test('gets no automatic frame at all', () {
      expect(Capture.none.capturesOnSuccess, isFalse);
      expect(Capture.none.capturesOnFailure, isFalse);
    });
  });
}
