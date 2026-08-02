part of com.demo.market.app_cross.core;

/// Raw SQL access to the `notifications` table.
class NotificationsDao extends BaseDao {
  const NotificationsDao(super.database);

  Future<void> insert(Map<String, Object?> row) async {
    final Database database = await db;
    await database.insert(DbTables.notifications, row);
  }

  Future<List<Map<String, Object?>>> forUser(String userId) async {
    final Database database = await db;
    return database.query(
      DbTables.notifications,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'created_at DESC, id DESC',
    );
  }

  Future<void> markRead(String notificationId) async {
    final Database database = await db;
    await database.update(
      DbTables.notifications,
      <String, Object?>{'is_read': 1},
      where: 'id = ?',
      whereArgs: <Object?>[notificationId],
    );
  }

  Future<void> markAllRead(String userId) async {
    final Database database = await db;
    await database.update(
      DbTables.notifications,
      <String, Object?>{'is_read': 1},
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
    );
  }

  Future<int> unreadCount(String userId) async {
    final Database database = await db;
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM ${DbTables.notifications} '
      'WHERE user_id = ? AND is_read = 0',
      <Object?>[userId],
    );
    return (rows.first['total'] as int?) ?? 0;
  }
}
