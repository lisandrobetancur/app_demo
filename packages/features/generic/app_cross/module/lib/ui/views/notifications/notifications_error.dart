part of com.demo.market.app_cross.ui.views.notifications;

/// Error state with retry.
class _NotificationsError extends ConsumerWidget {
  const _NotificationsError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: AppCrossKeys.notificationsState('error'),
    icon: AppIcons.error,
    title: 'app_cross.notifications.error_title'.tr(),
    actionLabel: 'app_cross.notifications.retry_button'.tr(),
    onAction: ref.read(notificationsViewModelProvider.notifier).load,
  );
}
