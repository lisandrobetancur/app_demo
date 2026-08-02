part of com.demo.market.dashboard.ui.views.home;

/// F06 · Dashboard home.
class DashboardHomeView extends ConsumerWidget {
  const DashboardHomeView({super.key});

  static const String route = DashboardRoutes.homePath;
  static const String name = DashboardRoutes.homeName;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: DashboardKeys.logoutConfirmDialog,
      title: 'dashboard.home.logout_title'.tr(),
      message: 'dashboard.home.logout_message'.tr(),
      confirmLabel: 'dashboard.home.confirm'.tr(),
      cancelLabel: 'dashboard.home.cancel'.tr(),
    );
    if (confirmed) {
      await ref.read(authenticationServiceProvider).logout();
      ref.read(dashboardNavigator.notifier).goToLogin();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeState state = ref.watch(homeViewModelProvider);
    final AuthUser? user = ref.watch(authSessionProvider);
    final int unread = ref.watch(unreadNotificationsCountProvider);
    return AppScaffold(
      key: DashboardKeys.view,
      titleWidget: Text(
        'dashboard.home.greeting'.tr(
          namedArgs: <String, String>{'name': user?.fullName ?? ''},
        ),
        key: DashboardKeys.greetingText,
        overflow: TextOverflow.ellipsis,
      ),
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: <Widget>[
        if (PlatformGuard.isWeb)
          IconButton(
            key: DashboardKeys.refreshButton,
            icon: const Icon(AppIcons.refresh),
            tooltip: 'dashboard.home.refresh_tooltip'.tr(),
            onPressed: ref.read(homeViewModelProvider.notifier).load,
          ),
        Semantics(
          label: 'dashboard.home.notifications_tooltip'.tr(),
          button: true,
          child: IconButton(
            key: DashboardKeys.notificationsButton,
            icon: AppBadge(
              count: unread,
              child: const Icon(AppIcons.notifications),
            ),
            tooltip: 'dashboard.home.notifications_tooltip'.tr(),
            onPressed: ref.read(dashboardNavigator.notifier).goToNotifications,
          ),
        ),
        IconButton(
          key: DashboardKeys.logoutButton,
          icon: const Icon(AppIcons.logout),
          tooltip: 'dashboard.home.logout_tooltip'.tr(),
          onPressed: () => _confirmLogout(context, ref),
        ),
      ],
      body: switch (state.status) {
        ViewStatus.loading => const _HomeShimmer(),
        ViewStatus.data => const _HomeData(),
        ViewStatus.empty => const _HomeEmpty(),
        ViewStatus.error => const _HomeError(),
      },
    );
  }
}
