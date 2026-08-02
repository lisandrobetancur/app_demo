part of com.demo.market.app_cross.core.state.notifications;

/// Riverpod handle for [NotificationsViewModel].
final NotifierProvider<NotificationsViewModel, NotificationsState>
notificationsViewModelProvider =
    NotifierProvider<NotificationsViewModel, NotificationsState>(
      NotificationsViewModel.new,
    );
