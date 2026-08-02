part of com.demo.market.catalog.core.state.detail;

/// Riverpod handle for [DetailViewModel].
final NotifierProvider<DetailViewModel, DetailState> detailViewModelProvider =
    NotifierProvider<DetailViewModel, DetailState>(DetailViewModel.new);
