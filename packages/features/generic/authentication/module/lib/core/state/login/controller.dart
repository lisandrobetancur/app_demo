part of com.demo.market.authentication.core.state.login;

/// Controller of the login form.
class LoginViewModel extends ViewModel<LoginState> {
  LoginViewModel({LoginState? state}) : super(state ?? const LoginState());

  @override
  void postInit() {
    service = ref.read(authenticationServiceProvider);
    navigatorNotifier = ref.read(authenticationNavigator.notifier);
  }

  late IAuthenticationService service;
  late AuthenticationNavigator navigatorNotifier;

  void setEmail(String value) =>
      state = state.copyWith(email: value, clearError: true);

  void setPassword(String value) =>
      state = state.copyWith(password: value, clearError: true);

  void toggleObscurePassword() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  void setRememberMe(bool value) => state = state.copyWith(rememberMe: value);

  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await service.login(
        email: state.email,
        password: state.password,
        rememberMe: state.rememberMe,
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
      log.error('login.submit', error, stackTrace);
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
