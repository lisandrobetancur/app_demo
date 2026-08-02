import 'package:navigator/navigator.dart';

import 'views/about/about.dart';
import 'views/notifications/notifications.dart';
import 'views/onboarding/onboarding.dart';
import 'views/settings/settings.dart';
import 'views/splash/splash.dart';

/// Routes contributed by the app_cross feature.
final List<AppRoute> appCrossRoutes = <AppRoute>[
  const AppRoute(SplashView.route, name: SplashView.name, widget: SplashView()),
  const AppRoute(
    OnboardingView.route,
    name: OnboardingView.name,
    widget: OnboardingView(),
  ),
  const AppRoute(
    NotificationsView.route,
    name: NotificationsView.name,
    widget: NotificationsView(),
  ),
  const AppRoute(
    SettingsView.route,
    name: SettingsView.name,
    widget: SettingsView(),
  ),
  const AppRoute(AboutView.route, name: AboutView.name, widget: AboutView()),
];
