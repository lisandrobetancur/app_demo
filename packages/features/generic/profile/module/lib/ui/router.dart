import 'package:navigator/navigator.dart';

import 'views/addresses/addresses.dart';
import 'views/profile/profile.dart';

/// Routes of this feature that live inside the navigation shell.
final List<AppRoute> profileShellRoutes = <AppRoute>[
  const AppRoute(
    ProfileView.route,
    name: ProfileView.name,
    widget: ProfileView(),
  ),
];

/// Full-screen routes of the profile feature.
final List<AppRoute> profileRoutes = <AppRoute>[
  const AppRoute(
    AddressesView.route,
    name: AddressesView.name,
    widget: AddressesView(),
  ),
];
