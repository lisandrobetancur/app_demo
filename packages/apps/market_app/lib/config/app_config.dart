import 'package:database/database.dart';

/// Boot flags, read from `--dart-define` in this single file and exposed to
/// the rest of the app through providers/overrides.
///
///  * `SEED_MODE=demo|empty` — deterministic seed content or empty database.
///  * `FAST_ANIMATIONS=true` — collapses every animation duration to zero.
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
}
