part of com.demo.market.catalog.core.state.form;

/// Riverpod handle for [FormViewModel].
final NotifierProvider<FormViewModel, FormState> formViewModelProvider =
    NotifierProvider<FormViewModel, FormState>(FormViewModel.new);
