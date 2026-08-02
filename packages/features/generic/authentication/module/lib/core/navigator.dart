part of com.demo.market.authentication.core;

/// Riverpod handle for [AuthenticationNavigator].
final NotifierProvider<AuthenticationNavigator, void> authenticationNavigator =
    NotifierProvider<AuthenticationNavigator, void>(
      AuthenticationNavigator.new,
    );

/// Navigation intents of the authentication feature.
///
/// Cross-feature destinations are plain route strings — this navigator never
/// imports another feature's module.
class AuthenticationNavigator extends FeatureNavigator {
  void goToLogin() => navigation.goNamed(AuthenticationRoutes.loginName);

  void goToRegister() => navigation.goNamed(AuthenticationRoutes.registerName);

  void goToRecoverPassword() =>
      navigation.goNamed(AuthenticationRoutes.recoverPasswordName);

  /// Post-login/register destination (dashboard feature, by path), or the
  /// deep link parked while the app was booting.
  void goToDashboard() => navigation.go(
    ref.read(bootstrapGateProvider).consumePending() ?? '/dashboard',
  );
}
