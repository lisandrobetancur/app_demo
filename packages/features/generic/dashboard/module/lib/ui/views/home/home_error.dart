part of com.demo.market.dashboard.ui.views.home;

/// Error state with retry.
class _HomeError extends ConsumerWidget {
  const _HomeError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: DashboardKeys.state('error'),
    icon: AppIcons.error,
    title: 'dashboard.home.error_title'.tr(),
    actionLabel: 'dashboard.home.retry_button'.tr(),
    onAction: ref.read(homeViewModelProvider.notifier).load,
  );
}
