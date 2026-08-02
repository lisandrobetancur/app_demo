import 'package:navigator/navigator.dart';

import 'views/cart/cart.dart';
import 'views/checkout/checkout.dart';
import 'views/checkout_success/checkout_success.dart';

/// Routes of this feature that live inside the navigation shell.
final List<AppRoute> cartShellRoutes = <AppRoute>[
  const AppRoute(CartView.route, name: CartView.name, widget: CartView()),
];

/// Full-screen routes of the cart feature.
final List<AppRoute> cartRoutes = <AppRoute>[
  const AppRoute(
    CheckoutView.route,
    name: CheckoutView.name,
    widget: CheckoutView(),
  ),
  const AppRoute(
    CheckoutSuccessView.route,
    name: CheckoutSuccessView.name,
    widget: CheckoutSuccessView(),
  ),
];
