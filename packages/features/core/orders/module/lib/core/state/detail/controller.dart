part of com.demo.market.orders.core.state.detail;

/// Controller of the order detail.
class OrderDetailViewModel extends ViewModel<OrderDetailState> {
  OrderDetailViewModel({OrderDetailState? state})
    : super(state ?? const OrderDetailState());

  @override
  void postInit() {
    service = ref.read(ordersServiceProvider);
    navigatorNotifier = ref.read(ordersNavigator.notifier);
  }

  late IOrdersService service;
  late OrdersNavigator navigatorNotifier;

  Future<void> load(String orderId) async {
    state = const OrderDetailState();
    final Object? key = mountedKey;
    try {
      final Order? order = await service.orderById(orderId);
      if (key != mountedKey) {
        return;
      }
      state = order == null
          ? state.copyWith(status: ViewStatus.empty)
          : state.copyWith(order: order, status: ViewStatus.data);
    } on Object catch (error, stackTrace) {
      log.error('orders.detail.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  /// Cancels the order (CREATED/PAID only) restoring stock transactionally.
  Future<void> cancel() async {
    final Order? order = state.order;
    if (order == null || !order.status.isCancellable || state.isCancelling) {
      return;
    }
    state = state.copyWith(isCancelling: true);
    final Object? key = mountedKey;
    try {
      await service.cancelOrder(order.id);
      ref.invalidate(ordersListViewModelProvider);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isCancelling: false,
        lastEventKey: 'orders.detail.cancelled_message',
      );
      await load(order.id);
    } on Object catch (error, stackTrace) {
      log.error('orders.detail.cancel', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isCancelling: false,
        lastEventKey: 'orders.detail.cancel_error',
      );
    }
  }

  /// Puts available items back into the cart and reports the missing ones.
  Future<void> reorder() async {
    final Order? order = state.order;
    final String? userId = ref.read(authSessionProvider)?.id;
    if (order == null || userId == null || state.isReordering) {
      return;
    }
    state = state.copyWith(isReordering: true);
    final Object? key = mountedKey;
    try {
      final ReorderResult result = await service.reorder(
        orderId: order.id,
        userId: userId,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isReordering: false,
        lastEventKey: result.hasUnavailable
            ? 'orders.detail.reorder_partial'
            : 'orders.detail.reorder_done',
        lastEventArg: result.hasUnavailable
            ? result.unavailableNames.join(', ')
            : '${result.addedCount}',
      );
    } on Object catch (error, stackTrace) {
      log.error('orders.detail.reorder', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isReordering: false,
        lastEventKey: 'orders.detail.reorder_error',
      );
    }
  }

  void consumeEvent() => state = state.copyWith(clearEvent: true);

  void goToCart() => navigatorNotifier.goToCart();
}
