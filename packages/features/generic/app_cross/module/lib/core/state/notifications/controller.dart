part of com.demo.market.app_cross.core.state.notifications;

/// Controller of the notifications tray.
class NotificationsViewModel extends ViewModel<NotificationsState> {
  NotificationsViewModel({NotificationsState? state})
    : super(state ?? const NotificationsState());

  @override
  void postInit() {
    service = ref.read(notificationsServiceProvider);
    navigatorNotifier = ref.read(appCrossNavigator.notifier);
    runPostBuild(load);
  }

  late INotificationsService service;
  late AppCrossNavigator navigatorNotifier;

  Future<void> load() async {
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final AuthUser? user = ref.read(authSessionProvider);
      if (user == null) {
        if (key != mountedKey) {
          return;
        }
        state = state.copyWith(
          notifications: const <AppNotification>[],
          status: ViewStatus.empty,
        );
        return;
      }
      final List<AppNotification> notifications = await service.forUser(
        user.id,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        notifications: notifications,
        status: notifications.isEmpty ? ViewStatus.empty : ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('notifications.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  /// Marks the notification as read and follows its deep link when present.
  Future<void> open(AppNotification notification) async {
    if (!notification.isRead) {
      await service.markRead(notification.id);
    }
    final String? route = notification.route;
    await load();
    if (route != null) {
      navigatorNotifier.openDeepLink(route);
    }
  }

  Future<void> markAllRead() async {
    final AuthUser? user = ref.read(authSessionProvider);
    if (user == null) {
      return;
    }
    await service.markAllRead(user.id);
    await load();
  }
}
