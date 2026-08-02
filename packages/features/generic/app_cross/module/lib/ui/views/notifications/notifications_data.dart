part of com.demo.market.app_cross.ui.views.notifications;

/// Data state: unread notifications highlighted, tap follows the deep link.
class _NotificationsData extends ConsumerWidget {
  const _NotificationsData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationsState state = ref.watch(notificationsViewModelProvider);
    final NotificationsViewModel viewModel = ref.read(
      notificationsViewModelProvider.notifier,
    );
    return ListView.separated(
      key: AppCrossKeys.notificationsState('data'),
      itemCount: state.notifications.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final AppNotification notification = state.notifications[index];
        return _NotificationTile(
          key: AppCrossKeys.notificationItem(notification.id),
          notification: notification,
          onTap: () => viewModel.open(notification),
        );
      },
    );
  }
}

/// One notification row.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(switch (notification.type) {
        NotificationType.welcome => AppIcons.checkFilled,
        NotificationType.orderCreated => AppIcons.orders,
        NotificationType.orderStatus => AppIcons.timeline,
        NotificationType.priceDrop => AppIcons.coupon,
      }, color: notification.isRead ? scheme.onSurfaceVariant : scheme.primary),
      title: Text(
        notification.titleKey.tr(namedArgs: notification.translationArgs),
        style: AppTypography.cardTitle.copyWith(
          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Text(
        notification.bodyKey.tr(namedArgs: notification.translationArgs),
        style: AppTypography.caption,
      ),
      trailing: Text(
        Formatters.formatDate(
          notification.createdAt,
          locale: context.locale.toString(),
        ),
        style: AppTypography.caption.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
