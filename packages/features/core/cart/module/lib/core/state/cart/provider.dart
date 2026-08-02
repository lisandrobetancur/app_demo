part of com.demo.market.cart.core.state.cart;

/// Riverpod handle for [CartViewModel].
final NotifierProvider<CartViewModel, CartState> cartViewModelProvider =
    NotifierProvider<CartViewModel, CartState>(CartViewModel.new);
