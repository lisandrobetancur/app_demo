part of com.demo.market.catalog.core.state.review_form;

/// Riverpod handle for [ReviewFormViewModel].
final NotifierProvider<ReviewFormViewModel, ReviewFormState>
reviewFormViewModelProvider =
    NotifierProvider<ReviewFormViewModel, ReviewFormState>(
      ReviewFormViewModel.new,
    );
