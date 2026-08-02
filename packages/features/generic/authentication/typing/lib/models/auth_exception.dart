/// Typed authentication failures.
enum AuthErrorCode {
  /// Wrong email/password pair. Deliberately generic: the UI never reveals
  /// whether the email exists.
  invalidCredentials,

  /// Registration with an email that already has an account.
  emailInUse,

  /// Password recovery requested for an unknown email.
  emailNotFound,

  /// Wrong recovery code.
  invalidCode,

  /// Wrong current password when changing it from the profile.
  wrongPassword;

  bool get isInvalidCredentials => this == AuthErrorCode.invalidCredentials;

  bool get isEmailInUse => this == AuthErrorCode.emailInUse;

  bool get isEmailNotFound => this == AuthErrorCode.emailNotFound;

  bool get isInvalidCode => this == AuthErrorCode.invalidCode;

  bool get isWrongPassword => this == AuthErrorCode.wrongPassword;

  /// Translation key for the inline error message.
  String get messageKey => switch (this) {
    AuthErrorCode.invalidCredentials =>
      'authentication.errors.invalid_credentials',
    AuthErrorCode.emailInUse => 'authentication.errors.email_in_use',
    AuthErrorCode.emailNotFound => 'authentication.errors.email_not_found',
    AuthErrorCode.invalidCode => 'authentication.errors.invalid_code',
    AuthErrorCode.wrongPassword => 'authentication.errors.wrong_password',
  };
}

/// Exception carrying a typed [AuthErrorCode].
class AuthException implements Exception {
  const AuthException(this.code);

  final AuthErrorCode code;

  @override
  String toString() => 'AuthException: ${code.name}';
}
