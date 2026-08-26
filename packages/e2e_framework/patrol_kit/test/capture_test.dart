import 'package:flutter/services.dart';
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

  group('a step that asks for the end-of-step frame', () {
    test('captures one that behaved and one that broke', () {
      expect(Capture.auto.capturesOnSuccess, isTrue);
      expect(Capture.auto.capturesOnFailure, isTrue);
    });
  });

  group('the caption a screenshot gets when nobody names it', () {
    test('is the clock, to the millisecond', () {
      expect(timeStamp(DateTime(2026, 8, 26, 14, 32, 7, 481)), '14:32:07.481');
    });

    test('pads every field, so captions sort and line up', () {
      expect(timeStamp(DateTime(2026, 1, 2, 3, 4, 5, 6)), '03:04:05.006');
    });

    test('carries no date, because a report describes one run', () {
      final String stamp = timeStamp(DateTime(2026, 8, 26, 14, 32, 7, 481));
      expect(stamp, isNot(contains('2026')));
      expect(stamp, isNot(contains('26')));
    });

    test('a failure caption carries the outcome between the two', () {
      // `failed` and `broken`, never a flat "fail": the report draws that
      // distinction everywhere else, and it is what a reader wants to know
      // before deciding whether to open the image.
      expect(
        BaseSteps.captionNow(tag: 'failed'),
        matches(RegExp(r'^failed · \d{2}:\d{2}:\d{2}\.\d{3}$')),
      );
      expect(BaseSteps.captionNow(tag: 'broken'), contains('broken'));
    });

    test('outside any step, it is the time and nothing else', () {
      // The suite never captures outside a step, but a caption is a string
      // and a null step name must not reach the report as the word "null".
      expect(
        BaseSteps.captionNow(),
        matches(RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}$')),
      );
    });
  });

  group('the default', () {
    // Pinned, because it is a decision rather than an accident: the author
    // places every frame of a passing run by hand, and the one nobody can
    // place — the screen as a failed expectation found it — is automatic.
    test('says nothing while a step behaves', () {
      expect(BaseSteps.defaultCapture, Capture.onFailure);
      expect(BaseSteps.defaultCapture.capturesOnSuccess, isFalse);
      expect(
        BaseSteps.defaultCapture.bracketsActions,
        isFalse,
        reason: 'a frame either side of every click is opt-in, not the default',
      );
    });

    test('still gets its picture when it breaks', () {
      expect(
        BaseSteps.defaultCapture.capturesOnFailure,
        isTrue,
        reason: 'nobody writes a shot for an expectation they thought held',
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

  group('a run of scrolls', () {
    setUp(() async {
      // Leave the ambient state as found, whatever a previous test did.
      await ActionCapture.closeScrollRun(
        (String _) async {},
        coveredByCaller: true,
      );
    });

    test('is opened by the first scroll and by no other', () {
      expect(ActionCapture.openScrollRun(), isTrue, reason: 'the first one');
      expect(
        ActionCapture.openScrollRun(),
        isFalse,
        reason: 'three scrolls down a form are one run, not three',
      );
      expect(ActionCapture.scrolling, isTrue);
    });

    test('lands with a frame when nothing else is about to look', () async {
      final List<String> taken = <String>[];
      ActionCapture.openScrollRun();

      await ActionCapture.closeScrollRun(
        (String name) async => taken.add(name),
        coveredByCaller: false,
      );

      expect(taken, <String>['after scrolling']);
      expect(ActionCapture.scrolling, isFalse);
    });

    test(
      'lands without one when the next action photographs it anyway',
      () async {
        final List<String> taken = <String>[];
        ActionCapture.openScrollRun();

        await ActionCapture.closeScrollRun(
          (String name) async => taken.add(name),
          coveredByCaller: true,
        );

        expect(
          taken,
          isEmpty,
          reason: "the click's own before frame is where the scrolling landed",
        );
        expect(ActionCapture.scrolling, isFalse);
      },
    );

    test('closing a run that was never open does nothing', () async {
      final List<String> taken = <String>[];
      await ActionCapture.closeScrollRun(
        (String name) async => taken.add(name),
        coveredByCaller: false,
      );
      expect(taken, isEmpty);
    });

    test('does not survive the step it happened in', () async {
      await ActionCapture.runWith(true, () async {
        ActionCapture.openScrollRun();
        expect(ActionCapture.scrolling, isTrue);
      });
      expect(
        ActionCapture.scrolling,
        isFalse,
        reason: 'the next step starts without a run half-open',
      );
    });
  });

  group('a key press', () {
    test('counts as an action when it activates what has focus', () {
      expect(keyActivates(LogicalKeyboardKey.enter), isTrue);
      expect(keyActivates(LogicalKeyboardKey.numpadEnter), isTrue);
      expect(keyActivates(LogicalKeyboardKey.space), isTrue);
    });

    test('counts as travel when it only moves the focus', () {
      expect(keyActivates(LogicalKeyboardKey.tab), isFalse);
      expect(keyActivates(LogicalKeyboardKey.arrowDown), isFalse);
      expect(
        keyActivates(LogicalKeyboardKey.escape),
        isFalse,
        reason: 'closing is not submitting; say acts: true if it matters',
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
