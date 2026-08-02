part of com.demo.market.authentication.core.state.login;

/// Riverpod handle for [LoginViewModel].
final NotifierProvider<LoginViewModel, LoginState> loginViewModelProvider =
    NotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);
