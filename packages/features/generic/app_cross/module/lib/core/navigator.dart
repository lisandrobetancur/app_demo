part of com.demo.market.app_cross.core;

/// Riverpod handle for [AppCrossNavigator].
final NotifierProvider<AppCrossNavigator, void> appCrossNavigator =
    NotifierProvider<AppCrossNavigator, void>(AppCrossNavigator.new);

/// Navigation intents of the app_cross feature.
class AppCrossNavigator extends FeatureNavigator {
  void goToOnboarding() => navigation.goNamed(AppCrossRoutes.onboardingName);

  void goToLogin() => navigation.goNamed(AuthenticationRoutes.loginName);

  /// Lands on the dashboard, or on the deep link parked during bootstrap.
  void goToDashboard() => navigation.go(
    ref.read(bootstrapGateProvider).consumePending() ?? '/dashboard',
  );

  void goToNotifications() =>
      navigation.pushNamed(AppCrossRoutes.notificationsName);

  void goToSettings() => navigation.goNamed(AppCrossRoutes.settingsName);

  void goToAbout() => navigation.pushNamed(AppCrossRoutes.aboutName);

  /// Follows the deep link stored in a notification payload.
  void openDeepLink(String route) => navigation.go(route);
}
