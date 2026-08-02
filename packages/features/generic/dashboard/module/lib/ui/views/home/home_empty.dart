part of com.demo.market.dashboard.ui.views.home;

/// Empty state (no active session).
class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: DashboardKeys.state('empty'),
    icon: AppIcons.home,
    title: 'dashboard.home.empty_title'.tr(),
  );
}
