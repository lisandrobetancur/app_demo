part of com.demo.market.catalog.core;

/// Raw SQL access for products, categories, favorites, reviews and search
/// history. Every list query has an explicit deterministic `ORDER BY` with a
/// stable `id` tie-breaker.
class CatalogDao extends BaseDao {
  const CatalogDao(super.database);

  static const String _productSelect =
      '''
SELECT p.*,
       c.code AS category_code,
       u.full_name AS owner_name,
       (SELECT AVG(r.rating) FROM ${DbTables.reviews} r
         WHERE r.product_id = p.id) AS rating_average,
       (SELECT COUNT(*) FROM ${DbTables.reviews} r
         WHERE r.product_id = p.id) AS rating_count
FROM ${DbTables.products} p
JOIN ${DbTables.categories} c ON c.id = p.category_id
JOIN ${DbTables.users} u ON u.id = p.owner_id
''';

  Future<List<Map<String, Object?>>> categories() async {
    final Database database = await db;
    return database.query(DbTables.categories, orderBy: 'name ASC, id ASC');
  }

  Future<List<Map<String, Object?>>> products({
    required ProductFilters filters,
    required int limit,
    required int offset,
  }) async {
    final Database database = await db;
    final _FilterClause clause = _FilterClause.from(filters);
    return database.rawQuery(
      '$_productSelect WHERE ${clause.where} '
      'ORDER BY ${_orderBy(filters.sort)} LIMIT ? OFFSET ?',
      <Object?>[...clause.args, limit, offset],
    );
  }

  Future<int> countProducts({required ProductFilters filters}) async {
    final Database database = await db;
    final _FilterClause clause = _FilterClause.from(filters);
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM ${DbTables.products} p '
      'WHERE ${clause.where}',
      clause.args,
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<Map<String, Object?>?> productById(String productId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '$_productSelect WHERE p.id = ? LIMIT 1',
      <Object?>[productId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> recentProducts(int limit) async {
    final Database database = await db;
    return database.rawQuery(
      "$_productSelect WHERE p.status = 'ACTIVE' "
      'ORDER BY p.created_at DESC, p.id ASC LIMIT ?',
      <Object?>[limit],
    );
  }

  Future<List<Map<String, Object?>>> productsByOwner(String ownerId) async {
    final Database database = await db;
    return database.rawQuery(
      "$_productSelect WHERE p.owner_id = ? AND p.status != 'DELETED' "
      'ORDER BY p.created_at DESC, p.id ASC',
      <Object?>[ownerId],
    );
  }

  Future<void> insertProduct(Map<String, Object?> row) async {
    final Database database = await db;
    await database.insert(DbTables.products, row);
  }

  Future<void> updateProduct(
    String productId,
    Map<String, Object?> values,
  ) async {
    final Database database = await db;
    await database.update(
      DbTables.products,
      values,
      where: 'id = ?',
      whereArgs: <Object?>[productId],
    );
  }

  // --- Favorites ---

  Future<List<Map<String, Object?>>> favoriteRows(String userId) async {
    final Database database = await db;
    return database.query(
      DbTables.favorites,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'created_at DESC, product_id ASC',
    );
  }

  Future<List<Map<String, Object?>>> favoriteProducts(String userId) async {
    final Database database = await db;
    return database.rawQuery(
      '$_productSelect JOIN ${DbTables.favorites} f ON f.product_id = p.id '
      'WHERE f.user_id = ? ORDER BY f.created_at DESC, p.id ASC',
      <Object?>[userId],
    );
  }

  Future<bool> isFavorite({
    required String userId,
    required String productId,
  }) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.query(
      DbTables.favorites,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: <Object?>[userId, productId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> insertFavorite({
    required String userId,
    required String productId,
    required int createdAt,
  }) async {
    final Database database = await db;
    await database.insert(DbTables.favorites, <String, Object?>{
      'user_id': userId,
      'product_id': productId,
      'created_at': createdAt,
    });
  }

  Future<void> deleteFavorite({
    required String userId,
    required String productId,
  }) async {
    final Database database = await db;
    await database.delete(
      DbTables.favorites,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: <Object?>[userId, productId],
    );
  }

  Future<int> favoritesCount(String userId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM ${DbTables.favorites} '
      'WHERE user_id = ?',
      <Object?>[userId],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  // --- Reviews ---

  Future<List<Map<String, Object?>>> reviewsFor(String productId) async {
    final Database database = await db;
    return database.rawQuery(
      'SELECT r.*, u.full_name AS user_name FROM ${DbTables.reviews} r '
      'JOIN ${DbTables.users} u ON u.id = r.user_id '
      'WHERE r.product_id = ? ORDER BY r.created_at DESC, r.id ASC',
      <Object?>[productId],
    );
  }

  Future<Map<String, Object?>?> reviewByUser({
    required String userId,
    required String productId,
  }) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT r.*, u.full_name AS user_name FROM ${DbTables.reviews} r '
      'JOIN ${DbTables.users} u ON u.id = r.user_id '
      'WHERE r.user_id = ? AND r.product_id = ? LIMIT 1',
      <Object?>[userId, productId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<bool> hasDeliveredPurchase({
    required String userId,
    required String productId,
  }) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT 1 FROM ${DbTables.orderItems} oi '
      'JOIN ${DbTables.orders} o ON o.id = oi.order_id '
      "WHERE o.user_id = ? AND o.status = 'DELIVERED' "
      'AND oi.product_id = ? LIMIT 1',
      <Object?>[userId, productId],
    );
    return rows.isNotEmpty;
  }

  Future<void> upsertReview(Map<String, Object?> row) async {
    final Database database = await db;
    await database.insert(
      DbTables.reviews,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Search history ---

  Future<List<Map<String, Object?>>> recentSearches({
    required String userId,
    required int limit,
  }) async {
    final Database database = await db;
    return database.rawQuery(
      'SELECT term, MAX(created_at) AS last_used '
      'FROM ${DbTables.searchHistory} WHERE user_id = ? '
      'GROUP BY term ORDER BY last_used DESC, term ASC LIMIT ?',
      <Object?>[userId, limit],
    );
  }

  Future<void> insertSearch(Map<String, Object?> row) async {
    final Database database = await db;
    await database.insert(DbTables.searchHistory, row);
  }
}

/// SQL fragment + args for the active-catalog filters.
class _FilterClause {
  const _FilterClause(this.where, this.args);

  factory _FilterClause.from(ProductFilters filters) {
    final StringBuffer where = StringBuffer("p.status = 'ACTIVE'");
    final List<Object?> args = <Object?>[];
    if (filters.query.trim().isNotEmpty) {
      where.write(' AND p.name LIKE ? COLLATE NOCASE');
      args.add('%${filters.query.trim()}%');
    }
    if (filters.categoryIds.isNotEmpty) {
      final String placeholders = List<String>.filled(
        filters.categoryIds.length,
        '?',
      ).join(', ');
      where.write(' AND p.category_id IN ($placeholders)');
      args.addAll(filters.categoryIds.toList()..sort());
    }
    if (filters.minPrice != null) {
      where.write(' AND p.price >= ?');
      args.add(filters.minPrice);
    }
    if (filters.maxPrice != null) {
      where.write(' AND p.price <= ?');
      args.add(filters.maxPrice);
    }
    if (filters.conditions.isNotEmpty) {
      final String placeholders = List<String>.filled(
        filters.conditions.length,
        '?',
      ).join(', ');
      where.write(' AND p.condition IN ($placeholders)');
      args.addAll(
        filters.conditions
            .map((ProductCondition condition) => condition.dbValue)
            .toList()
          ..sort(),
      );
    }
    if (filters.onlyInStock) {
      where.write(' AND p.stock > 0');
    }
    return _FilterClause(where.toString(), args);
  }

  final String where;
  final List<Object?> args;
}

String _orderBy(ProductSort sort) => switch (sort) {
  ProductSort.recent => 'p.created_at DESC, p.id ASC',
  ProductSort.priceAsc => 'p.price ASC, p.id ASC',
  ProductSort.priceDesc => 'p.price DESC, p.id ASC',
  ProductSort.bestRated =>
    'rating_average IS NULL, rating_average DESC, p.id ASC',
};
