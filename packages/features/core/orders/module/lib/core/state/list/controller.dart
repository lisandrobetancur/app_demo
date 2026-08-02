part of com.demo.market.orders.core.state.list;

/// Controller of the orders history.
class OrdersListViewModel extends ViewModel<OrdersListState> {
  OrdersListViewModel({OrdersListState? state})
    : super(state ?? const OrdersListState());

  @override
  void postInit() {
    service = ref.read(ordersServiceProvider);
    navigatorNotifier = ref.read(ordersNavigator.notifier);
    runPostBuild(load);
  }

  late IOrdersService service;
  late OrdersNavigator navigatorNotifier;

  Future<void> load() async {
    final String? userId = ref.read(authSessionProvider)?.id;
    if (userId == null) {
      state = state.copyWith(status: ViewStatus.empty);
      return;
    }
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final List<Order> orders = await service.ordersFor(
        userId,
        status: state.statusFilter,
        query: state.query,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        orders: orders,
        status: orders.isEmpty ? ViewStatus.empty : ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('orders.list.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  Future<void> setStatusFilter(OrderStatus? status) async {
    state = status == null
        ? state.copyWith(clearStatusFilter: true)
        : state.copyWith(statusFilter: status);
    await load();
  }

  Future<void> setQuery(String query) async {
    state = state.copyWith(query: query);
    await load();
  }

  void openDetail(String orderId) => navigatorNotifier.goToDetail(orderId);
}
