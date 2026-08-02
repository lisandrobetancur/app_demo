part of com.demo.market.catalog.core.state.favorites;

/// Riverpod handle for [FavoritesViewModel].
final NotifierProvider<FavoritesViewModel, FavoritesState>
favoritesViewModelProvider =
    NotifierProvider<FavoritesViewModel, FavoritesState>(
      FavoritesViewModel.new,
    );
