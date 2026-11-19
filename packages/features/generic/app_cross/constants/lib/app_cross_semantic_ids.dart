/// Semantics identifiers of the app-cross feature, grouped per view.
///
/// The counterpart of `app_cross_keys.dart` for tools that cannot see a
/// Flutter `Key`: Appium and Maestro on mobile, Playwright on the web. Each one
/// reaches the platform's accessibility layer as Android's `resource-id`,
/// iOS's `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// Contracts, like the keys: `<screen>_<element>_<type>` in English
/// snake_case, stable across language, country, theme and platform.

/// Semantics identifiers of the splash view.
class SplashSemanticIds {
  const SplashSemanticIds._();

  static const String view = 'splash_view';
  static const String loadingText = 'splash_loading_text';
  static const String errorText = 'splash_error_text';
  static const String retryButton = 'splash_retry_button';
}

/// Semantics identifiers of the onboarding view.
class OnboardingSemanticIds {
  const OnboardingSemanticIds._();

  static const String view = 'onboarding_view';
  static const String skipButton = 'onboarding_skip_button';
  static const String nextButton = 'onboarding_next_button';
  static const String startButton = 'onboarding_start_button';

  /// `onboarding_page_<n>`, n from 1: the pages are a fixed sequence, so the
  /// number names the page rather than a position in changing data.
  static String page(int page) => 'onboarding_page_$page';
}
