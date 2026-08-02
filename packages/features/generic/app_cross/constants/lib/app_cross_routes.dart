/// Route table of the app_cross feature.
///
/// Paths are kebab-case and feature-prefixed; names are stable identifiers
/// used for named navigation. Other features reach these routes through
/// `app_cross_typing`, never by importing the module.
class AppCrossRoutes {
  const AppCrossRoutes._();

  static const String splashPath = '/splash';
  static const String splashName = 'App Cross Splash';

  static const String onboardingPath = '/onboarding';
  static const String onboardingName = 'App Cross Onboarding';

  static const String notificationsPath = '/notifications';
  static const String notificationsName = 'App Cross Notifications';

  static const String settingsPath = '/settings';
  static const String settingsName = 'App Cross Settings';

  static const String aboutPath = '/settings-about';
  static const String aboutName = 'App Cross About';
}
