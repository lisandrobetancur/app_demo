part of com.demo.market.dashboard.core;

/// Aggregation queries of the dashboard.
class DashboardDao extends BaseDao {
  const DashboardDao(super.database);

  Future<int> activePublications(String userId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM ${DbTables.products} '
      "WHERE owner_id = ? AND status = 'ACTIVE'",
      <Object?>[userId],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<(int, double)> cartSummary(String userId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS lines, '
      'COALESCE(SUM(p.price * ci.quantity), 0) AS subtotal '
      'FROM ${DbTables.cartItems} ci '
      'JOIN ${DbTables.products} p ON p.id = ci.product_id '
      'WHERE ci.user_id = ?',
      <Object?>[userId],
    );
    final Map<String, Object?> row = rows.first;
    return (
      (row['lines'] as int?) ?? 0,
      ((row['subtotal'] as num?) ?? 0).toDouble(),
    );
  }

  Future<int> ordersInRange({
    required String userId,
    required int fromMillis,
    required int toMillis,
  }) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM ${DbTables.orders} '
      'WHERE user_id = ? AND created_at >= ? AND created_at < ? '
      "AND status != 'CANCELLED'",
      <Object?>[userId, fromMillis, toMillis],
    );
    return (rows.first['total'] as int?) ?? 0;
  }
}
