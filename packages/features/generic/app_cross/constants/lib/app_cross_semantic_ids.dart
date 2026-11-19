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

/// Semantics identifiers of the notifications tray.
class NotificationsSemanticIds {
  const NotificationsSemanticIds._();

  static const String view = 'notifications_view';
  static const String titleText = 'notifications_title_text';
  static const String markAllReadButton = 'notifications_mark_all_read_button';
  static const String retryButton = 'notifications_retry_button';

  /// `notifications_state_<loading|data|empty|error>`.
  static String state(String state) => 'notifications_state_$state';

  /// `notifications_item_<id>`.
  static String item(String id) => 'notifications_item_$id';
}

/// Semantics identifiers of the settings view.
class SettingsSemanticIds {
  const SettingsSemanticIds._();

  static const String view = 'settings_view';
  static const String titleText = 'settings_title_text';
  static const String languageSelector = 'settings_language_selector';
  static const String themeSelector = 'settings_theme_selector';
  static const String currencySelector = 'settings_currency_selector';
  static const String errorText = 'settings_error_text';
  static const String seeOnboardingAgainButton =
      'settings_see_onboarding_again_button';
  static const String resetDemoDataButton = 'settings_reset_demo_data_button';
  static const String resetDemoDataDialog = 'settings_reset_demo_data_dialog';
  static const String resetDemoDataConfirmButton =
      'settings_reset_demo_data_dialog_confirm_button';
  static const String resetDemoDataCancelButton =
      'settings_reset_demo_data_dialog_cancel_button';
  static const String wipeDataButton = 'settings_wipe_data_button';
  static const String wipeDataDialog = 'settings_wipe_data_dialog';
  static const String wipeDataConfirmButton =
      'settings_wipe_data_dialog_confirm_button';
  static const String wipeDataCancelButton =
      'settings_wipe_data_dialog_cancel_button';
  static const String goToAboutButton = 'settings_go_to_about_button';

  /// `settings_language_option_<es|en>`. Carries the selected state.
  static String languageOption(String code) => 'settings_language_option_$code';

  /// `settings_theme_option_<system|light|dark>`.
  static String themeOption(String mode) => 'settings_theme_option_$mode';

  /// `settings_currency_option_<code>`.
  static String currencyOption(String code) => 'settings_currency_option_$code';
}

/// Semantics identifiers of the about view.
class AboutSemanticIds {
  const AboutSemanticIds._();

  static const String view = 'about_view';
  static const String titleText = 'about_title_text';
  static const String versionText = 'about_version_text';
  static const String platformText = 'about_platform_text';
}
