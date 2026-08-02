part of com.demo.market.authentication.core.state.recover;

/// Steps of the password recovery flow.
enum RecoverStep {
  email,
  code,
  password;

  bool get isEmail => this == RecoverStep.email;

  bool get isCode => this == RecoverStep.code;

  bool get isPassword => this == RecoverStep.password;
}

/// Immutable state of the password recovery flow.
class RecoverState {
  const RecoverState({
    this.step = RecoverStep.email,
    this.email = '',
    this.issuedCode = '',
    this.codeInput = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.completed = false,
    this.errorKey,
  });

  final RecoverStep step;
  final String email;

  /// Demo code shown in the banner (locally generated, deterministic).
  final String issuedCode;

  final String codeInput;
  final String newPassword;
  final String confirmPassword;
  final bool isSubmitting;

  /// True once the password was reset; the view reacts by returning to
  /// login with a confirmation message.
  final bool completed;

  final String? errorKey;

  String? get emailErrorKey => email.isEmpty || Validators.isValidEmail(email)
      ? null
      : 'authentication.validation.email_invalid';

  String? get newPasswordErrorKey =>
      newPassword.isEmpty || Validators.isValidPassword(newPassword)
      ? null
      : 'authentication.validation.password_invalid';

  String? get confirmPasswordErrorKey =>
      confirmPassword.isEmpty || confirmPassword == newPassword
      ? null
      : 'authentication.validation.confirm_mismatch';

  bool get canSendCode => !isSubmitting && Validators.isValidEmail(email);

  bool get canValidateCode => !isSubmitting && codeInput.length == 6;

  bool get canSubmitPassword =>
      !isSubmitting &&
      Validators.isValidPassword(newPassword) &&
      confirmPassword == newPassword;

  RecoverState copyWith({
    RecoverStep? step,
    String? email,
    String? issuedCode,
    String? codeInput,
    String? newPassword,
    String? confirmPassword,
    bool? isSubmitting,
    bool? completed,
    String? errorKey,
    bool clearError = false,
  }) => RecoverState(
    step: step ?? this.step,
    email: email ?? this.email,
    issuedCode: issuedCode ?? this.issuedCode,
    codeInput: codeInput ?? this.codeInput,
    newPassword: newPassword ?? this.newPassword,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    completed: completed ?? this.completed,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is RecoverState &&
      other.step == step &&
      other.email == email &&
      other.issuedCode == issuedCode &&
      other.codeInput == codeInput &&
      other.newPassword == newPassword &&
      other.confirmPassword == confirmPassword &&
      other.isSubmitting == isSubmitting &&
      other.completed == completed &&
      other.errorKey == errorKey;

  @override
  int get hashCode => Object.hash(
    step,
    email,
    issuedCode,
    codeInput,
    newPassword,
    confirmPassword,
    isSubmitting,
    completed,
    errorKey,
  );

  @override
  String toString() =>
      'RecoverState: step:${step.name} submitting:$isSubmitting '
      'error:$errorKey';
}
