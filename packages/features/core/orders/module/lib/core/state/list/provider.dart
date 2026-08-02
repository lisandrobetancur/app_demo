part of com.demo.market.orders.core.state.list;

/// Riverpod handle for [OrdersListViewModel].
final NotifierProvider<OrdersListViewModel, OrdersListState>
ordersListViewModelProvider =
    NotifierProvider<OrdersListViewModel, OrdersListState>(
      OrdersListViewModel.new,
    );
