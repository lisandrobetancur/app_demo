part of com.demo.market.dashboard.core.state.home;

/// Riverpod handle for [HomeViewModel].
final NotifierProvider<HomeViewModel, HomeState> homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
