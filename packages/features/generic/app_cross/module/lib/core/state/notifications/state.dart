part of com.demo.market.app_cross.core.state.notifications;

/// Immutable state of the notifications tray.
class NotificationsState {
  const NotificationsState({
    this.notifications = const <AppNotification>[],
    this.status = ViewStatus.loading,
  });

  final List<AppNotification> notifications;
  final ViewStatus status;

  int get unreadCount => notifications
      .where((AppNotification notification) => !notification.isRead)
      .length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    ViewStatus? status,
  }) => NotificationsState(
    notifications: notifications ?? this.notifications,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationsState &&
      other.status == status &&
      _listEquals(other.notifications, notifications);

  @override
  int get hashCode => Object.hash(status, Object.hashAll(notifications));

  @override
  String toString() =>
      'NotificationsState: ${notifications.length} items ${status.name}';

  static bool _listEquals(List<AppNotification> a, List<AppNotification> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
