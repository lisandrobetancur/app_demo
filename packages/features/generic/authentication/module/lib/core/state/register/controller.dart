part of com.demo.market.authentication.core.state.register;

/// Controller of the registration form.
class RegisterViewModel extends ViewModel<RegisterState> {
  RegisterViewModel({RegisterState? state})
    : super(state ?? const RegisterState());

  @override
  void postInit() {
    service = ref.read(authenticationServiceProvider);
    navigatorNotifier = ref.read(authenticationNavigator.notifier);
  }

  late IAuthenticationService service;
  late AuthenticationNavigator navigatorNotifier;

  void setFullName(String value) =>
      state = state.copyWith(fullName: value, clearError: true);

  void setEmail(String value) =>
      state = state.copyWith(email: value, clearError: true);

  void setPhone(String value) =>
      state = state.copyWith(phone: value, clearError: true);

  void setPassword(String value) =>
      state = state.copyWith(password: value, clearError: true);

  void setConfirmPassword(String value) =>
      state = state.copyWith(confirmPassword: value, clearError: true);

  void setTermsAccepted(bool value) =>
      state = state.copyWith(termsAccepted: value);

  void toggleObscurePassword() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  void goToLogin() => navigatorNotifier.goToLogin();

  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await service.register(
        fullName: state.fullName,
        email: state.email,
        password: state.password,
        phone: state.phone,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isSubmitting: false);
      navigatorNotifier.goToDashboard();
    } on AuthException catch (error) {
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorKey: error.code.messageKey,
      );
    } on Object catch (error, stackTrace) {
      log.error('register.submit', error, stackTrace);
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
