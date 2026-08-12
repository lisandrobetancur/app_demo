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
/// Screenshots travel to the runner as base64 inside console output, so they
/// are deliberately small: legible for a report, cheap to move around.
const double _captureScale = 0.5;

/// Base64 is emitted in chunks because `debugPrint` wraps long lines, which
/// would corrupt a single huge payload.
const int _chunkSize = 800;

/// Marker the Allure converter looks for in the test's stdout.
const String _marker = 'PATROL_SHOT';

/// Capturing costs roughly 150 ms per interaction, so a run that only needs a
/// pass/fail answer can switch it off:
/// `patrol test --device chrome --dart-define=E2E_SCREENSHOTS=false`.
const bool screenshotsEnabled = bool.fromEnvironment(
  'E2E_SCREENSHOTS',
  defaultValue: true,
);

/// Captures the current frame and streams it to the runner.
///
/// Patrol exposes no screenshot action on the web (its native action list
/// covers taps, text, cookies and dialogs, but not captures), so the frame is
/// rasterised inside the app and printed to the browser console, which the
/// Playwright bridge forwards to the test's stdout.
///
/// Failures here never fail a test: a missing screenshot is a worse report,
/// not a wrong result.
Future<void> captureScreenshot(PatrolIntegrationTester $, String name) async {
  if (!screenshotsEnabled) {
    return;
  }
  try {
    await $.pump(const Duration(milliseconds: 16));
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
