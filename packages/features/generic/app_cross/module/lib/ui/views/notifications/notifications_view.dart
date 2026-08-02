part of com.demo.market.app_cross.ui.views.notifications;

/// F16 · Notifications tray.
class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  static const String route = AppCrossRoutes.notificationsPath;
  static const String name = AppCrossRoutes.notificationsName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationsState state = ref.watch(notificationsViewModelProvider);
    return AppScaffold(
      key: AppCrossKeys.notificationsView,
      title: 'app_cross.notifications.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: <Widget>[
        IconButton(
          key: AppCrossKeys.markAllReadButton,
          icon: const Icon(AppIcons.checkFilled),
          tooltip: 'app_cross.notifications.mark_all_read'.tr(),
          onPressed: state.unreadCount == 0
              ? null
              : ref.read(notificationsViewModelProvider.notifier).markAllRead,
        ),
      ],
      body: switch (state.status) {
        ViewStatus.loading => const _NotificationsShimmer(),
        ViewStatus.data => const _NotificationsData(),
        ViewStatus.empty => const _NotificationsEmpty(),
        ViewStatus.error => const _NotificationsError(),
      },
    );
  }
}
