part of com.demo.market.orders.core.state.list;

/// Immutable state of the orders history (F13).
class OrdersListState {
  const OrdersListState({
    this.orders = const <Order>[],
    this.statusFilter,
    this.query = '',
    this.status = ViewStatus.loading,
  });

  final List<Order> orders;

  /// Optional status filter; `null` means all statuses.
  final OrderStatus? statusFilter;

  /// Order-number search term.
  final String query;

  final ViewStatus status;

  OrdersListState copyWith({
    List<Order>? orders,
    OrderStatus? statusFilter,
    String? query,
    ViewStatus? status,
    bool clearStatusFilter = false,
  }) => OrdersListState(
    orders: orders ?? this.orders,
    statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
    query: query ?? this.query,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is OrdersListState &&
      other.statusFilter == statusFilter &&
      other.query == query &&
      other.status == status &&
      other.orders.length == orders.length &&
      _sameOrders(other.orders, orders);

  @override
  int get hashCode =>
      Object.hash(statusFilter, query, status, Object.hashAll(orders));

  @override
  String toString() =>
      'OrdersListState: ${orders.length} orders ${status.name} '
      'filter:${statusFilter?.name}';

  static bool _sameOrders(List<Order> a, List<Order> b) {
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
