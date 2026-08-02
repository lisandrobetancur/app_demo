import 'package:navigator/navigator.dart';

import 'views/detail/detail.dart';
import 'views/list/list.dart';

/// Routes of this feature that live inside the navigation shell.
final List<AppRoute> ordersShellRoutes = <AppRoute>[
  const AppRoute(
    OrdersListView.route,
    name: OrdersListView.name,
    widget: OrdersListView(),
  ),
];

/// Full-screen routes of the orders feature.
final List<AppRoute> ordersRoutes = <AppRoute>[
  const AppRoute(
    OrderDetailView.route,
    name: OrderDetailView.name,
    widget: OrderDetailView(),
  ),
];
