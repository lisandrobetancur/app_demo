import 'package:database/database.dart';

/// Boot flags, read from `--dart-define` in this single file and exposed to
/// the rest of the app through providers/overrides.
///
///  * `SEED_MODE=demo|empty` — deterministic seed content or empty database.
///  * `FAST_ANIMATIONS=true` — collapses every animation duration to zero.
///  * `ENABLE_SEMANTICS=true` — builds the semantics tree from the first
///    frame, for black-box automation (Playwright on the web). QA builds only.
class AppConfig {
  const AppConfig._();

  static const String _seedModeRaw = String.fromEnvironment(
    'SEED_MODE',
    defaultValue: 'demo',
  );

  /// Database seeding mode for this run.
  static SeedMode get seedMode => SeedMode.parse(_seedModeRaw);

  /// When true, `AppDurations` collapses to zero at bootstrap.
  static const bool fastAnimations = bool.fromEnvironment('FAST_ANIMATIONS');

  /// When true, the semantics tree is on from boot instead of on demand.
  ///
  /// It matters on the web: Flutter paints on a canvas, and the semantics tree
  /// is the only DOM a browser tool can see — the `flt-semantics` elements
  /// carrying each widget's `flt-semantics-identifier`. Off by default, the
  /// web only builds that tree once a screen reader asks for it, so a
  /// Playwright test would find an empty page. Android and iOS build theirs
  /// whenever an accessibility client queries the app, which is what
  /// UiAutomator, XCUITest, Appium and Maestro do, so they need no flag.
  ///
  /// Never on in production: keeping the tree in sync costs every frame.
  static const bool enableSemantics = bool.fromEnvironment('ENABLE_SEMANTICS');
}
