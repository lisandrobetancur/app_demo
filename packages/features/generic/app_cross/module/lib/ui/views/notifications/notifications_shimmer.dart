part of com.demo.market.app_cross.ui.views.notifications;

/// Loading skeleton (stops as soon as data arrives).
class _NotificationsShimmer extends StatelessWidget {
  const _NotificationsShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      key: AppCrossKeys.notificationsState('loading'),
      padding: AppSpacing.pagePadding,
      itemCount: 6,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          const AppShimmerBox(height: 64),
    ),
  );
}
