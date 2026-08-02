part of com.demo.market.cart.core;

/// Raw SQL access to `cart_items` and `coupons`.
class CartDao extends BaseDao {
  const CartDao(super.database);

  static const String _lineSelect =
      '''
SELECT ci.id, ci.user_id, ci.product_id, ci.quantity, ci.added_at,
       p.name AS product_name, p.price AS unit_price, p.stock,
       p.status AS product_status, p.image_path,
       c.code AS category_code
FROM ${DbTables.cartItems} ci
JOIN ${DbTables.products} p ON p.id = ci.product_id
JOIN ${DbTables.categories} c ON c.id = p.category_id
''';

  Future<List<Map<String, Object?>>> linesFor(String userId) async {
    final Database database = await db;
    return database.rawQuery(
      '$_lineSelect WHERE ci.user_id = ? '
      'ORDER BY ci.added_at ASC, ci.id ASC',
      <Object?>[userId],
    );
  }

  Future<Map<String, Object?>?> lineByProduct({
    required String userId,
    required String productId,
  }) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.query(
      DbTables.cartItems,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: <Object?>[userId, productId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> insertLine(Map<String, Object?> row) async {
    final Database database = await db;
    await database.insert(DbTables.cartItems, row);
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final Database database = await db;
    await database.update(
      DbTables.cartItems,
      <String, Object?>{'quantity': quantity},
      where: 'id = ?',
      whereArgs: <Object?>[cartItemId],
    );
  }

  Future<void> deleteLine(String cartItemId) async {
    final Database database = await db;
    await database.delete(
      DbTables.cartItems,
      where: 'id = ?',
      whereArgs: <Object?>[cartItemId],
    );
  }

  Future<void> clear(String userId) async {
    final Database database = await db;
    await database.delete(
      DbTables.cartItems,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
    );
  }

  Future<Map<String, Object?>?> couponByCode(String code) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.query(
      DbTables.coupons,
      where: 'code = ?',
      whereArgs: <Object?>[code],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Line count and subtotal for the shared badge providers.
  Future<(int, double)> badgeFor(String userId) async {
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
}
