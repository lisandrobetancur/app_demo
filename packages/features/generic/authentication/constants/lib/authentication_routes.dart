/// Route table of the authentication feature.
class AuthenticationRoutes {
  const AuthenticationRoutes._();

  static const String loginPath = '/authentication/login';
  static const String loginName = 'Authentication Login';

  static const String registerPath = '/authentication/register';
  static const String registerName = 'Authentication Register';

  static const String recoverPasswordPath = '/authentication/recover-password';
  static const String recoverPasswordName = 'Authentication Recover Password';
}
