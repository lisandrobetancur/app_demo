part of com.demo.market.app_cross.ui.views.notifications;

/// Empty state of the notifications tray.
class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: AppCrossKeys.notificationsState('empty'),
    icon: AppIcons.notifications,
    title: 'app_cross.notifications.empty_title'.tr(),
    message: 'app_cross.notifications.empty_message'.tr(),
  );
}
