part of com.demo.market.orders.core.state.detail;

/// Immutable state of the order detail (F13).
class OrderDetailState {
  const OrderDetailState({
    this.order,
    this.status = ViewStatus.loading,
    this.isCancelling = false,
    this.isReordering = false,
    this.lastEventKey,
    this.lastEventArg = '',
  });

  final Order? order;
  final ViewStatus status;
  final bool isCancelling;
  final bool isReordering;

  /// One-shot translation key consumed by the view as a snackbar.
  final String? lastEventKey;

  final String lastEventArg;

  OrderDetailState copyWith({
    Order? order,
    ViewStatus? status,
    bool? isCancelling,
    bool? isReordering,
    String? lastEventKey,
    String? lastEventArg,
    bool clearEvent = false,
  }) => OrderDetailState(
    order: order ?? this.order,
    status: status ?? this.status,
    isCancelling: isCancelling ?? this.isCancelling,
    isReordering: isReordering ?? this.isReordering,
    lastEventKey: clearEvent ? null : lastEventKey ?? this.lastEventKey,
    lastEventArg: clearEvent ? '' : lastEventArg ?? this.lastEventArg,
  );

  @override
  bool operator ==(Object other) =>
      other is OrderDetailState &&
      other.order == order &&
      other.status == status &&
      other.isCancelling == isCancelling &&
      other.isReordering == isReordering &&
      other.lastEventKey == lastEventKey &&
      other.lastEventArg == lastEventArg;

  @override
  int get hashCode => Object.hash(
    order,
    status,
    isCancelling,
    isReordering,
    lastEventKey,
    lastEventArg,
  );

  @override
  String toString() => 'OrderDetailState: ${order?.id} ${status.name}';
}
