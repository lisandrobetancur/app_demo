part of com.demo.market.cart.core.state.checkout;

/// Riverpod handle for [CheckoutViewModel].
final NotifierProvider<CheckoutViewModel, CheckoutState>
checkoutViewModelProvider = NotifierProvider<CheckoutViewModel, CheckoutState>(
  CheckoutViewModel.new,
);
