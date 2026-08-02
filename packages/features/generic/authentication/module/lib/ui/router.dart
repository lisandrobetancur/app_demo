import 'package:navigator/navigator.dart';

import 'views/login/login.dart';
import 'views/recover_password/recover_password.dart';
import 'views/register/register.dart';

/// Routes contributed by the authentication feature.
final List<AppRoute> authenticationRoutes = <AppRoute>[
  const AppRoute(LoginView.route, name: LoginView.name, widget: LoginView()),
  const AppRoute(
    RegisterView.route,
    name: RegisterView.name,
    widget: RegisterView(),
  ),
  const AppRoute(
    RecoverPasswordView.route,
    name: RecoverPasswordView.name,
    widget: RecoverPasswordView(),
  ),
];
