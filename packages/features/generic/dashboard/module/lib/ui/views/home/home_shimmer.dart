part of com.demo.market.dashboard.ui.views.home;

/// Loading skeleton of the dashboard.
class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView(
      key: DashboardKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      children: const <Widget>[
        AppShimmerBox(height: 120),
        SizedBox(height: AppSpacing.lg),
        AppShimmerBox(height: 96),
        SizedBox(height: AppSpacing.lg),
        AppShimmerBox(height: 168),
        SizedBox(height: AppSpacing.lg),
        AppShimmerBox(height: 96),
      ],
    ),
  );
}
