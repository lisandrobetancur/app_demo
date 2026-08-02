part of com.demo.market.catalog.core.state.list;

/// Riverpod handle for [ListViewModel].
final NotifierProvider<ListViewModel, ListState> listViewModelProvider =
    NotifierProvider<ListViewModel, ListState>(ListViewModel.new);
