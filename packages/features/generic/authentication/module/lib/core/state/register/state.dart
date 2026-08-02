part of com.demo.market.authentication.core.state.register;

/// Immutable state of the registration form.
class RegisterState {
  const RegisterState({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.termsAccepted = false,
    this.obscurePassword = true,
    this.isSubmitting = false,
    this.errorKey,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final bool termsAccepted;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? errorKey;

  String? get fullNameErrorKey =>
      fullName.isEmpty || fullName.trim().length >= 3
      ? null
      : 'authentication.validation.name_required';

  String? get emailErrorKey => email.isEmpty || Validators.isValidEmail(email)
      ? null
      : 'authentication.validation.email_invalid';

  String? get passwordErrorKey =>
      password.isEmpty || Validators.isValidPassword(password)
      ? null
      : 'authentication.validation.password_invalid';

  String? get confirmPasswordErrorKey =>
      confirmPassword.isEmpty || confirmPassword == password
      ? null
      : 'authentication.validation.confirm_mismatch';

  bool get canSubmit =>
      !isSubmitting &&
      fullName.trim().length >= 3 &&
      Validators.isValidEmail(email) &&
      Validators.isValidPassword(password) &&
      confirmPassword == password &&
      termsAccepted;

  RegisterState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    bool? termsAccepted,
    bool? obscurePassword,
    bool? isSubmitting,
    String? errorKey,
    bool clearError = false,
  }) => RegisterState(
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    termsAccepted: termsAccepted ?? this.termsAccepted,
    obscurePassword: obscurePassword ?? this.obscurePassword,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is RegisterState &&
      other.fullName == fullName &&
      other.email == email &&
      other.phone == phone &&
      other.password == password &&
      other.confirmPassword == confirmPassword &&
      other.termsAccepted == termsAccepted &&
      other.obscurePassword == obscurePassword &&
      other.isSubmitting == isSubmitting &&
      other.errorKey == errorKey;

  @override
  int get hashCode => Object.hash(
    fullName,
    email,
    phone,
    password,
    confirmPassword,
    termsAccepted,
    obscurePassword,
    isSubmitting,
    errorKey,
  );

  @override
  String toString() =>
      'RegisterState: email:$email submitting:$isSubmitting error:$errorKey';
}
