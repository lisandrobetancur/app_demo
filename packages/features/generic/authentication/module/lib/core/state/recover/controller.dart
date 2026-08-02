part of com.demo.market.authentication.core.state.recover;

/// Controller of the password recovery flow.
class RecoverViewModel extends ViewModel<RecoverState> {
  RecoverViewModel({RecoverState? state})
    : super(state ?? const RecoverState());

  @override
  void postInit() {
    service = ref.read(authenticationServiceProvider);
    navigatorNotifier = ref.read(authenticationNavigator.notifier);
  }

  late IAuthenticationService service;
  late AuthenticationNavigator navigatorNotifier;

  void setEmail(String value) =>
      state = state.copyWith(email: value, clearError: true);

  void setCodeInput(String value) =>
      state = state.copyWith(codeInput: value, clearError: true);

  void setNewPassword(String value) =>
      state = state.copyWith(newPassword: value, clearError: true);

  void setConfirmPassword(String value) =>
      state = state.copyWith(confirmPassword: value, clearError: true);

  void backToLogin() => navigatorNotifier.goToLogin();

  Future<void> sendCode() async {
    if (!state.canSendCode) {
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final Object? key = mountedKey;
    try {
      final String code = await service.requestRecoveryCode(email: state.email);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        issuedCode: code,
        step: RecoverStep.code,
      );
    } on AuthException catch (error) {
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorKey: error.code.messageKey,
      );
    } on Object catch (error, stackTrace) {
      log.error('recover.sendCode', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorKey: 'authentication.errors.generic',
      );
    }
  }

  void validateCode() {
    if (!state.canValidateCode) {
      return;
    }
    if (state.codeInput != state.issuedCode) {
      state = state.copyWith(errorKey: AuthErrorCode.invalidCode.messageKey);
      return;
    }
    state = state.copyWith(step: RecoverStep.password, clearError: true);
  }

  Future<void> submitNewPassword() async {
    if (!state.canSubmitPassword) {
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await service.resetPassword(
        email: state.email,
        code: state.codeInput,
        newPassword: state.newPassword,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isSubmitting: false, completed: true);
    } on AuthException catch (error) {
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorKey: error.code.messageKey,
      );
    } on Object catch (error, stackTrace) {
      log.error('recover.submitNewPassword', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorKey: 'authentication.errors.generic',
      );
    }
  }
}
