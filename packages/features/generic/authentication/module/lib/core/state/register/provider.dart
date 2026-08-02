part of com.demo.market.authentication.core.state.register;

/// Riverpod handle for [RegisterViewModel].
final NotifierProvider<RegisterViewModel, RegisterState>
registerViewModelProvider = NotifierProvider<RegisterViewModel, RegisterState>(
  RegisterViewModel.new,
);
