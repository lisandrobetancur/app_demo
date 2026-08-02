import 'package:flutter/foundation.dart';

/// Widget keys of the app_cross feature.
///
/// Keys are contracts: they never depend on language, theme, platform or
/// copy. Views always reference these constants, never literals.
class AppCrossKeys {
  const AppCrossKeys._();

  // F01 · Splash.
  static const Key splashView = Key('splash_view');
  static const Key splashRetryButton = Key('splash_retry_button');

  // F02 · Onboarding.
  static const Key onboardingView = Key('onboarding_view');
  static const Key onboardingSkipButton = Key('onboarding_skip_button');
  static const Key onboardingNextButton = Key('onboarding_next_button');
  static const Key onboardingStartButton = Key('onboarding_start_button');

  /// `onboarding_page_<n>` (1-based page number, stable across languages).
  static Key onboardingPage(int page) => Key('onboarding_page_$page');

  // F16 · Notifications tray.
  static const Key notificationsView = Key('notifications_view');
  static const Key markAllReadButton = Key('mark_all_read_button');

  /// `notification_item_<id>` (entity id, never a list index).
  static Key notificationItem(String id) => Key('notification_item_$id');

  /// `notifications_state_<estado>`.
  static Key notificationsState(String state) =>
      Key('notifications_state_$state');

  // F16 · Settings.
  static const Key settingsView = Key('settings_view');
  static const Key languageSelector = Key('language_selector');
  static const Key themeSelector = Key('theme_selector');
  static const Key currencySelector = Key('currency_selector');
  static const Key seeOnboardingAgainButton = Key(
    'see_onboarding_again_button',
  );
  static const Key resetDemoDataButton = Key('reset_demo_data_button');
  static const Key wipeDataButton = Key('wipe_data_button');
  static const Key resetDemoDataDialog = Key('reset_demo_data_dialog');
  static const Key wipeDataDialog = Key('wipe_data_dialog');
  static const Key goToAboutButton = Key('go_to_about_button');
  static const Key aboutView = Key('about_view');

  /// `language_option_<code>` inside the language selector.
  static Key languageOption(String code) => Key('language_option_$code');

  /// `theme_option_<mode>` inside the theme selector.
  static Key themeOption(String mode) => Key('theme_option_$mode');

  /// `currency_option_<code>` inside the currency selector.
  static Key currencyOption(String code) => Key('currency_option_$code');
}
