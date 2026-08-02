import '../enums/order_status.dart';
import '../models/order.dart';
import '../models/reorder_result.dart';

/// Orders contract: history, detail, cancellation and re-order.
abstract interface class IOrdersService {
  /// Orders of [userId], newest first, optionally filtered by [status] and
  /// by an order-number [query].
  Future<List<Order>> ordersFor(
    String userId, {
    OrderStatus? status,
    String query = '',
  });

  /// One order with its items, or `null`.
  Future<Order?> orderById(String orderId);

  /// Orders of [userId] created in the month of [reference] (dashboard).
  Future<int> countOrdersInMonth(String userId, DateTime reference);

  /// Cancels a `CREATED`/`PAID` order and restores stock, in one
  /// transaction. Throws [StateError] when the status does not allow it.
  Future<void> cancelOrder(String orderId);

  /// Puts the still-available items back into the cart and reports the ones
  /// that are not available anymore.
  Future<ReorderResult> reorder({
    required String orderId,
    required String userId,
  });
}
