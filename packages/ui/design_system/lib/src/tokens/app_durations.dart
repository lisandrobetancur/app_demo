/// Duration tokens.
///
/// When the app boots with `--dart-define=FAST_ANIMATIONS=true`, the shell
/// sets [fastMode] and every duration collapses to [Duration.zero], letting
/// the UI reach steady state instantly (deterministic walkthroughs).
class AppDurations {
  const AppDurations._();

  /// Set once at bootstrap by the shell; never toggled afterwards.
  static bool fastMode = false;

  static Duration get fast =>
      fastMode ? Duration.zero : const Duration(milliseconds: 150);

  static Duration get medium =>
      fastMode ? Duration.zero : const Duration(milliseconds: 300);

  static Duration get slow =>
      fastMode ? Duration.zero : const Duration(milliseconds: 500);

  /// Search debounce (catalog search input).
  static Duration get debounce =>
      fastMode ? Duration.zero : const Duration(milliseconds: 300);

  /// One shimmer sweep. Shimmer only renders while a view is loading, so it
  /// never keeps the UI busy once data arrives.
  static Duration get shimmerPeriod =>
      fastMode ? Duration.zero : const Duration(milliseconds: 1200);

  /// Snackbar visibility (e.g. the "undo remove" window in the cart).
  static Duration get snackBar =>
      fastMode ? const Duration(milliseconds: 300) : const Duration(seconds: 4);
}
