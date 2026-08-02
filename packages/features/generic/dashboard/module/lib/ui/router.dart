import 'package:navigator/navigator.dart';

import 'views/home/home.dart';

/// Routes of this feature that live inside the navigation shell.
final List<AppRoute> dashboardShellRoutes = <AppRoute>[
  const AppRoute(
    DashboardHomeView.route,
    name: DashboardHomeView.name,
    widget: DashboardHomeView(),
  ),
];
