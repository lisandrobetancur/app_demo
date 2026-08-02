part of com.demo.market.dashboard.core;

/// Concrete [IDashboardService].
class DashboardService implements IDashboardService {
  DashboardService({required DashboardDao dao}) : _dao = dao;

  final DashboardDao _dao;

  @override
  Future<DashboardSummary> summaryFor({
    required String userId,
    required DateTime reference,
  }) async {
    final int publications = await _dao.activePublications(userId);
    final (int cartCount, double cartSubtotal) = await _dao.cartSummary(userId);
    final DateTime from = DateTime(reference.year, reference.month);
    final DateTime to = DateTime(reference.year, reference.month + 1);
    final int monthOrders = await _dao.ordersInRange(
      userId: userId,
      fromMillis: from.millisecondsSinceEpoch,
      toMillis: to.millisecondsSinceEpoch,
    );
    return DashboardSummary(
      activePublications: publications,
      cartItemCount: cartCount,
      cartSubtotal: cartSubtotal,
      ordersThisMonth: monthOrders,
    );
  }
}
