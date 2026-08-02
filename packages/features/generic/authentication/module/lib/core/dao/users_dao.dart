part of com.demo.market.authentication.core;

/// Raw SQL access to the `users` table.
class UsersDao extends BaseDao {
  const UsersDao(super.database);

  Future<Map<String, Object?>?> findByEmail(String email) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.query(
      DbTables.users,
      where: 'email = ?',
      whereArgs: <Object?>[email],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> findById(String id) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.query(
      DbTables.users,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> insert(Map<String, Object?> row) async {
    final Database database = await db;
    await database.insert(DbTables.users, row);
  }

  Future<void> updatePassword({
    required String userId,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final Database database = await db;
    await database.update(
      DbTables.users,
      <String, Object?>{
        'password_hash': passwordHash,
        'password_salt': passwordSalt,
      },
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );
  }
}
