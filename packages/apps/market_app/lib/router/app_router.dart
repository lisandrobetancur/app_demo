import 'package:app_cross/app_cross.dart';
import 'package:app_cross_typing/app_cross_typing.dart';
import 'package:authentication/authentication.dart';
import 'package:authentication_typing/authentication_typing.dart';
import 'package:cart/cart.dart';
import 'package:catalog/catalog.dart';
import 'package:dashboard/dashboard.dart';
import 'package:dashboard_typing/dashboard_typing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navigator/navigator.dart';
import 'package:orders/orders.dart';
import 'package:profile/profile.dart';

import 'app_navigation_shell.dart';
import 'not_found_view.dart';

/// Builds the app router from the routes every feature contributes.
///
/// The shell owns: the `StatefulShellRoute` (bottom bar / rail with one
/// preserved branch per tab), the global session redirect and the
/// `market://` deep-link normalization.
GoRouter buildAppRouter(Ref ref) {
  // Re-evaluate the redirect whenever the session changes.
  final ValueNotifier<int> sessionTick = ValueNotifier<int>(0);
  ref
    ..listen<AuthUser?>(
      authSessionProvider,
      (AuthUser? previous, AuthUser? next) => sessionTick.value++,
    )
    ..onDispose(sessionTick.dispose);
  return GoRouter(
    initialLocation: AppCrossRoutes.splashPath,
    refreshListenable: sessionTick,
    errorBuilder: (BuildContext context, GoRouterState state) =>
        const NotFoundView(),
    redirect: (BuildContext context, GoRouterState state) {
      // market://catalog/detail/x → /catalog/detail/x
      if (state.uri.scheme == DeepLinks.scheme) {
        return DeepLinks.normalize(state.uri);
      }
      final String location = state.uri.path;
      final BootstrapGate gate = ref.read(bootstrapGateProvider);
      // Cold start: park whatever was requested and boot first, so a deep
      // link is not swallowed by the session redirect.
      if (!gate.isReady) {
        if (location == AppCrossRoutes.splashPath) {
          return null;
        }
        if (location != '/') {
          gate.remember(state.uri.toString());
        }
        return AppCrossRoutes.splashPath;
      }
      final bool loggedIn = ref.read(authSessionProvider) != null;
      final bool onBootstrap =
          location == AppCrossRoutes.splashPath ||
          location == AppCrossRoutes.onboardingPath;
      final bool onAuthentication = location.startsWith('/authentication');
      if (onBootstrap) {
        return null;
      }
      if (!loggedIn && !onAuthentication) {
        return AuthenticationRoutes.loginPath;
      }
      if (loggedIn && onAuthentication) {
        return DashboardRoutes.homePath;
      }
      return null;
    },
    routes: <RouteBase>[
      for (final AppRoute route in appCrossRoutes) route.toGoRoute(),
      for (final AppRoute route in authenticationRoutes) route.toGoRoute(),
      for (final AppRoute route in catalogRoutes) route.toGoRoute(),
      for (final AppRoute route in cartRoutes) route.toGoRoute(),
      for (final AppRoute route in ordersRoutes) route.toGoRoute(),
      for (final AppRoute route in profileRoutes) route.toGoRoute(),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => AppNavigationShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              for (final AppRoute route in dashboardShellRoutes)
                route.toGoRoute(),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              for (final AppRoute route in catalogShellRoutes)
                route.toGoRoute(),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              for (final AppRoute route in cartShellRoutes) route.toGoRoute(),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              for (final AppRoute route in ordersShellRoutes) route.toGoRoute(),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              for (final AppRoute route in profileShellRoutes)
                route.toGoRoute(),
            ],
          ),
        ],
      ),
    ],
  );
}
