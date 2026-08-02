part of com.demo.market.orders.core;

/// Raw SQL access to `orders` and `order_items`.
class OrdersDao extends BaseDao {
  const OrdersDao(super.database);

  static const String _orderSelect =
      '''
SELECT o.*, a.label AS address_label
FROM ${DbTables.orders} o
LEFT JOIN ${DbTables.addresses} a ON a.id = o.address_id
''';

  Future<List<Map<String, Object?>>> ordersFor(
    String userId, {
    String? statusDbValue,
  }) async {
    final Database database = await db;
    final StringBuffer where = StringBuffer('o.user_id = ?');
    final List<Object?> args = <Object?>[userId];
    if (statusDbValue != null) {
      where.write(' AND o.status = ?');
      args.add(statusDbValue);
    }
    return database.rawQuery(
      '$_orderSelect WHERE $where ORDER BY o.created_at DESC, o.id ASC',
      args,
    );
  }

  Future<Map<String, Object?>?> orderById(String orderId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '$_orderSelect WHERE o.id = ? LIMIT 1',
      <Object?>[orderId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> itemsFor(String orderId) async {
    final Database database = await db;
    return database.query(
      DbTables.orderItems,
      where: 'order_id = ?',
      whereArgs: <Object?>[orderId],
      orderBy: 'name ASC, id ASC',
    );
  }

  Future<int> countInRange({
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
