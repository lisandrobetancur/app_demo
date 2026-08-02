/// Limits and fixed values of the app_cross feature.
class AppCrossLimits {
  const AppCrossLimits._();

  /// Number of onboarding slides.
  static const int onboardingPages = 3;

  /// `shared_preferences` flag set once onboarding has been seen.
  static const String onboardingSeenPrefKey = 'app_cross.onboarding_seen';

  /// `shared_preferences` key for the persisted theme mode.
  static const String themeModePrefKey = 'app_cross.theme_mode';

  /// `shared_preferences` key for the persisted display currency.
  static const String currencyPrefKey = 'app_cross.display_currency';
}
