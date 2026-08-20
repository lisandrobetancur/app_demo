import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

/// Anchors the repaint boundary the screenshots are taken from.
///
/// The launcher wraps the whole app in a `RepaintBoundary` carrying this key,
/// so a capture is exactly what the user would see.
final GlobalKey appBoundaryKey = GlobalKey(debugLabel: 'patrol_app_boundary');

/// How much the captured frame is scaled down before encoding.
///
/// Screenshots travel to the runner as base64 inside console output, in
/// [_chunkSize] pieces, so every pixel has a price and the frame is scaled
/// down before encoding.
///
/// Three quarters and not a half, which is where this started. At a half, a
/// capture of a 1080-wide app came out 540 wide — and the report shows it at
/// its own size, because upscaling a bitmap makes it bigger without making it
/// legible. Half was too little to read an error message under a form field,
/// which is the thing somebody opens a screenshot to read.
///
/// The cost is real and worth stating: three quarters is 2.25 times the
/// pixels of a half, so roughly twice the base64 and twice the chunks per
/// capture. That is paid on every screenshot of every run. Full resolution
/// would double it again to read no better — the app is not rendering finer
/// detail than this, it is rendering text.
const double _captureScale = 0.75;

/// Base64 is emitted in chunks because a single very long line gets mangled
/// on the way out of the browser.
const int _chunkSize = 800;

/// Marker the report generator looks for in the test's stdout.
const String _marker = 'PATROL_SHOT';

/// Capturing costs roughly 150 ms, so a run that only needs a pass/fail
/// answer can switch it off:
/// `patrol test --device chrome --dart-define=E2E_SCREENSHOTS=false`.
const bool screenshotsEnabled = bool.fromEnvironment(
  'E2E_SCREENSHOTS',
  defaultValue: true,
);

/// When a business step captures the screen.
///
/// Every step takes a frame when it ends, and that default is the right one:
/// the picture nobody thought to ask for is the one wanted at three in the
/// morning when a step failed on CI. But a suite of forty steps produces forty
/// images, and some of them show nothing worth keeping — a step that only
/// reads a value, one whose screen is identical to the step before it, one
/// that spends its time on a network call behind a spinner.
///
/// So the default stays and the exceptions get a name. Whatever the policy, a
/// step can always take extra frames by hand with [BaseSteps.shot], which is
/// how you capture a moment *inside* a step rather than at its end — the
/// dialog before it is dismissed, the list before the filter is applied.
enum Capture {
  /// A frame when the step ends, and another if it breaks. The default.
  auto,

  /// The default, plus a frame either side of every **click** and every
  /// **clear** the step performs.
  ///
  /// For the steps where what vanishes is the point: the form as it was
  /// filled, captured as the *before* of the click that sends it; the menu
  /// before the tap that closes it; the field before it is emptied.
  ///
  /// Typing is deliberately not bracketed. A field with text in it is the
  /// same screen with text in it, and a frame either side of every keystroke
  /// target would bury the two that matter under a dozen near-identical
  /// ones.
  aroundActions,

  /// Nothing while the step behaves; a frame if it breaks.
  ///
  /// For steps whose end state says nothing — but whose failure still needs
  /// to be looked at, which is every step.
  onFailure,

  /// No frame, ever, not even on failure.
  ///
  /// For a step that captures what it needs by hand, and for the rare one
  /// where an automatic frame would be actively misleading.
  none;

  /// Whether a step that behaved should be captured.
  bool get capturesOnSuccess =>
      this == Capture.auto || this == Capture.aroundActions;

  /// Whether every interaction inside the step captures either side of
  /// itself.
  bool get bracketsActions => this == Capture.aroundActions;

  /// Whether a step that broke should be captured.
  ///
  /// True for everything except [none]: a failure with no picture is the
  /// case the screenshots exist for.
  bool get capturesOnFailure => this != Capture.none;
}

/// Whether interactions are currently bracketing themselves with frames.
///
/// Ambient rather than passed down, because the alternative is threading a
/// flag through every page object and every element — the page layer would
/// have to know about screenshots to stay out of their way, which is exactly
/// the coupling the layers exist to prevent.
///
/// A single mutable field is enough: a Patrol test owns its isolate and runs
/// its steps one after another, so there is never a second step reading this
/// at the same time. [runWith] restores what it found, so nesting works and
/// an exception cannot leave it stuck on.
abstract final class ActionCapture {
  static bool _enabled = false;
  static bool _scrolling = false;

  /// True while interactions should capture either side of themselves.
  static bool get enabled => _enabled;

  /// True while a run of scrolls is open — see [openScrollRun].
  static bool get scrolling => _scrolling;

  /// Opens a run of scrolls, returning true if this is the one that starts
  /// it.
  ///
  /// Scrolling is rarely one call. A step walks down a long form scrolling
  /// three or four times, and a frame either side of each would be four
  /// pictures of the same page sliding past. What is worth seeing is where
  /// the scrolling started and where it landed, so the first scroll of a run
  /// takes the *before* and the run stays open until something else happens.
  static bool openScrollRun() {
    if (_scrolling) {
      return false;
    }
    _scrolling = true;
    return true;
  }

  /// Closes an open run of scrolls, capturing where it landed.
  ///
  /// [coveredByCaller] is how the duplicate is avoided: an action that takes
  /// its own *before* frame is already photographing the screen the scrolling
  /// landed on, and so is the frame a step takes when it ends. Only when
  /// nothing else is about to look — a scroll followed by typing, say — does
  /// the landing need a picture of its own.
  static Future<void> closeScrollRun(
    Future<void> Function(String name) shoot, {
    required bool coveredByCaller,
  }) async {
    if (!_scrolling) {
      return;
    }
    _scrolling = false;
    if (!coveredByCaller) {
      await shoot('after scrolling');
    }
  }

  /// Runs [body] with [value] in force, then puts back what was there.
  ///
  /// Any run of scrolls left open ends with the body: the step's own frame is
  /// the last word on where it finished.
  static Future<T> runWith<T>(bool value, Future<T> Function() body) async {
    final bool previous = _enabled;
    final bool wasScrolling = _scrolling;
    _enabled = value;
    _scrolling = false;
    try {
      return await body();
    } finally {
      _enabled = previous;
      _scrolling = wasScrolling;
    }
  }
}

/// Captures either side of [action]: the screen it starts from, and the one
/// it leaves behind.
///
/// The state *before* an action is the one that disappears. A form submitted
/// with the wrong data is gone the instant it is sent — the screen that
/// answers "what exactly did we type?" only exists until the tap lands — and
/// the automatic frame a step takes shows where the step ended, which is
/// already the other side of it.
///
/// The [after] frame is taken even when the action throws, because that is
/// when both pictures matter most: the form as it was, and whatever the
/// product did with it.
///
/// [shoot] is how a frame is taken; [BaseSteps.capturing] passes its own.
Future<T> captureAround<T>(
  Future<void> Function(String name) shoot,
  Future<T> Function() action, {
  required String before,
  required String after,
}) async {
  await shoot(before);
  try {
    return await action();
  } finally {
    await shoot(after);
  }
}

/// Gives Patrol the screenshot API it does not ship on the web.
///
/// Patrol's web automation exposes taps, text, cookies, dialogs and window
/// control, but no capture — and its Dart API has no `takeScreenshot`. This
/// extension fills that gap so a test can write:
///
/// ```dart
/// await $.takeScreenshot('cart_with_coupon');
/// ```
///
/// The frame is rasterised inside the app from [appBoundaryKey] and printed
/// to the browser console, which the Playwright bridge forwards into the
/// test's stdout, where the report generator reassembles it.
extension PatrolScreenshot on PatrolIntegrationTester {
  /// Captures the current frame and streams it to the runner under [name].
  ///
  /// Failures here never fail a test: a missing screenshot is a worse report,
  /// not a wrong result.
  Future<void> takeScreenshot(String name) async {
    if (!screenshotsEnabled) {
      return;
    }
    try {
      await pump(const Duration(milliseconds: 16));
      final RenderObject? renderObject = appBoundaryKey.currentContext
          ?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return;
      }

      final ui.Image image = await renderObject.toImage(
        pixelRatio: _captureScale,
      );
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      if (data == null) {
        return;
      }

      final String encoded = base64Encode(data.buffer.asUint8List());
      final int total = (encoded.length / _chunkSize).ceil();
      for (int index = 0; index < total; index++) {
        final int start = index * _chunkSize;
        final int end = (start + _chunkSize).clamp(0, encoded.length);
        // `debugPrint` throttles to about 1 KB/s and silently drops the rest,
        // which shredded the payload; the synchronous variant writes it whole.
        debugPrintSynchronously(
          '$_marker|$name|$index|$total|${encoded.substring(start, end)}',
        );
      }
    } on Object catch (error) {
      debugPrintSynchronously('$_marker|ERROR|$name|$error');
    }
  }
}
