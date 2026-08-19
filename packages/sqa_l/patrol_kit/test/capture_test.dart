import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// When a step captures the screen, and when it stays out of the way.
void main() {
  group('capturing an action', () {
    test('takes the before frame, runs it, then the after frame', () async {
      final List<String> taken = <String>[];
      final List<String> order = <String>[];

      final String result = await captureAround(
        (String name) async => taken.add(name),
        () async {
          order.add('action');
          return 'submitted';
        },
        before: 'Credentials as typed',
        after: 'What the submit produced',
      );

      expect(result, 'submitted', reason: 'the action\'s value passes through');
      expect(taken, <String>[
        'Credentials as typed',
        'What the submit produced',
      ]);
      expect(order, <String>['action']);
    });

    test('still takes the after frame when the action throws', () async {
      final List<String> taken = <String>[];

      await expectLater(
        captureAround(
          (String name) async => taken.add(name),
          () async => throw StateError('the submit blew up'),
          before: 'the form as it was',
          after: 'what the product did with it',
        ),
        throwsStateError,
      );

      expect(taken, <String>[
        'the form as it was',
        'what the product did with it',
      ], reason: 'a failed action is when both pictures matter most');
    });
  });

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

  group('a step that brackets its interactions', () {
    test('keeps its own end frame as well', () {
      expect(Capture.aroundActions.bracketsActions, isTrue);
      expect(
        Capture.aroundActions.capturesOnSuccess,
        isTrue,
        reason: 'bracketing the actions is on top of the default, not instead',
      );
      expect(Capture.auto.bracketsActions, isFalse);
      expect(Capture.none.bracketsActions, isFalse);
    });
  });

  group('the ambient switch interactions read', () {
    test('is off until a step turns it on, and off again after', () async {
      expect(ActionCapture.enabled, isFalse);
      await ActionCapture.runWith(true, () async {
        expect(ActionCapture.enabled, isTrue);
      });
      expect(ActionCapture.enabled, isFalse);
    });

    test('restores what it found, even when the step blows up', () async {
      await ActionCapture.runWith(true, () async {
        await expectLater(
          ActionCapture.runWith(
            false,
            () async => throw StateError('the step blew up'),
          ),
          throwsStateError,
        );
        expect(
          ActionCapture.enabled,
          isTrue,
          reason: 'a nested scope puts back the outer one, failure or not',
        );
      });
      expect(ActionCapture.enabled, isFalse);
    });
  });

  group('a step that captures by hand', () {
    test('gets no automatic frame at all', () {
      expect(Capture.none.capturesOnSuccess, isFalse);
      expect(Capture.none.capturesOnFailure, isFalse);
    });
  });
}
