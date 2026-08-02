part of com.demo.market.orders.core.state.detail;

/// Riverpod handle for [OrderDetailViewModel].
final NotifierProvider<OrderDetailViewModel, OrderDetailState>
orderDetailViewModelProvider =
    NotifierProvider<OrderDetailViewModel, OrderDetailState>(
      OrderDetailViewModel.new,
    );
