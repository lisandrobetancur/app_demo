part of com.demo.market.app_cross.core;

/// Concrete [INotificationsService].
///
/// Keeps the shared unread counter (`unreadNotificationsCountProvider`) in
/// sync after every write so badges react without re-querying from the UI.
class NotificationsService implements INotificationsService {
  NotificationsService({
    required NotificationsDao dao,
    required Clock clock,
    required IdGenerator idGenerator,
    required StateController<int> unreadCount,
    required StateController<AuthUser?> session,
  }) : _dao = dao,
       _clock = clock,
       _idGenerator = idGenerator,
       _unreadCount = unreadCount,
       _session = session;

  final NotificationsDao _dao;
  final Clock _clock;
  final IdGenerator _idGenerator;
  final StateController<int> _unreadCount;
  final StateController<AuthUser?> _session;

  @override
  Future<void> create({
    required String userId,
    required NotificationType type,
    required String titleKey,
    required String bodyKey,
    String? payload,
  }) async {
    await _dao.insert(<String, Object?>{
      'id': _idGenerator.newId(),
      'user_id': userId,
      'type': type.dbValue,
      'title_key': titleKey,
      'body_key': bodyKey,
      'payload': payload,
      'is_read': 0,
      'created_at': _clock().millisecondsSinceEpoch,
    });
    await _refreshIfActive(userId);
  }

  @override
  Future<List<AppNotification>> forUser(String userId) async {
    final List<Map<String, Object?>> rows = await _dao.forUser(userId);
    return rows.map(AppNotification.fromMap).toList();
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _dao.markRead(notificationId);
    final AuthUser? user = _session.state;
    if (user != null) {
      await refreshUnreadCount(user.id);
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    await _dao.markAllRead(userId);
    await _refreshIfActive(userId);
  }

  @override
  Future<int> refreshUnreadCount(String userId) async {
    final int count = await _dao.unreadCount(userId);
    _unreadCount.state = count;
    return count;
  }

  Future<void> _refreshIfActive(String userId) async {
    if (_session.state?.id == userId) {
      await refreshUnreadCount(userId);
    }
  }
}
