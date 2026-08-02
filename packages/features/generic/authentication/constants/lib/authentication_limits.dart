/// Limits and fixed values of the authentication feature.
class AuthenticationLimits {
  const AuthenticationLimits._();

  /// Minimum password length (plus one letter and one digit).
  static const int passwordMinLength = 8;

  /// Length of the demo recovery code.
  static const int recoveryCodeLength = 6;

  /// `shared_preferences` key holding the remembered user id.
  static const String sessionUserIdPrefKey = 'authentication.session_user_id';
}
