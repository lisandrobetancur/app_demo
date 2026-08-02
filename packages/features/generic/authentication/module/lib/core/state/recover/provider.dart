part of com.demo.market.authentication.core.state.recover;

/// Riverpod handle for [RecoverViewModel].
final NotifierProvider<RecoverViewModel, RecoverState>
recoverViewModelProvider = NotifierProvider<RecoverViewModel, RecoverState>(
  RecoverViewModel.new,
);
