part of com.demo.market.authentication.core.state.login;

/// Immutable state of the login form.
class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.isSubmitting = false,
    this.errorKey,
  });

  final String email;
  final String password;
  final bool obscurePassword;
  final bool isSubmitting;

  /// Translation key of the submit error, `null` when there is none.
  final String? errorKey;

  /// Live validation: only complains once the user typed something.
  String? get emailErrorKey => email.isEmpty || Validators.isValidEmail(email)
      ? null
      : 'authentication.validation.email_invalid';

  bool get canSubmit =>
      !isSubmitting && Validators.isValidEmail(email) && password.isNotEmpty;

  LoginState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? isSubmitting,
    String? errorKey,
    bool clearError = false,
  }) => LoginState(
    email: email ?? this.email,
    password: password ?? this.password,
    obscurePassword: obscurePassword ?? this.obscurePassword,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is LoginState &&
      other.email == email &&
      other.password == password &&
      other.obscurePassword == obscurePassword &&
      other.isSubmitting == isSubmitting &&
      other.errorKey == errorKey;

  @override
  int get hashCode => Object.hash(
    email,
    password,
    obscurePassword,
    isSubmitting,
    errorKey,
  );

  @override
  String toString() =>
      'LoginState: email:$email submitting:$isSubmitting error:$errorKey';
}
