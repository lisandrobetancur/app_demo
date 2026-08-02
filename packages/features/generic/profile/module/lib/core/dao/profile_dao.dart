part of com.demo.market.profile.core;

/// Raw SQL access for user profile data and addresses.
class ProfileDao extends BaseDao {
  const ProfileDao(super.database);

  Future<void> updateUser(String userId, Map<String, Object?> values) async {
    final Database database = await db;
    await database.update(
      DbTables.users,
      values,
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );
  }

  Future<Map<String, Object?>?> userById(String userId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.query(
      DbTables.users,
      where: 'id = ?',
      whereArgs: <Object?>[userId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> deleteUser(String userId) async {
    final Database database = await db;
    await database.delete(
      DbTables.users,
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );
  }

  Future<List<Map<String, Object?>>> addressesFor(String userId) async {
    final Database database = await db;
    return database.query(
      DbTables.addresses,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'is_default DESC, label ASC, id ASC',
    );
  }

  Future<void> insertAddress(Map<String, Object?> row) async {
    final Database database = await db;
    await database.insert(DbTables.addresses, row);
  }

  Future<void> updateAddress(
    String addressId,
    Map<String, Object?> values,
  ) async {
    final Database database = await db;
    await database.update(
      DbTables.addresses,
      values,
      where: 'id = ?',
      whereArgs: <Object?>[addressId],
    );
  }

  Future<void> deleteAddress(String addressId) async {
    final Database database = await db;
    await database.delete(
      DbTables.addresses,
      where: 'id = ?',
      whereArgs: <Object?>[addressId],
    );
  }

  /// True when a non-final order (not delivered/cancelled) references it.
  Future<bool> isAddressUsedByActiveOrder(String addressId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT 1 FROM ${DbTables.orders} WHERE address_id = ? '
      "AND status NOT IN ('DELIVERED', 'CANCELLED') LIMIT 1",
      <Object?>[addressId],
    );
    return rows.isNotEmpty;
  }

  Future<int> countAddresses(String userId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM ${DbTables.addresses} '
      'WHERE user_id = ?',
      <Object?>[userId],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<void> clearDefaultAddresses(
    DatabaseExecutor executor,
    String userId,
  ) => executor.update(
    DbTables.addresses,
    <String, Object?>{'is_default': 0},
    where: 'user_id = ?',
    whereArgs: <Object?>[userId],
  );
}
