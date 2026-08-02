part of com.demo.market.orders.ui.views.detail;

/// Loading skeleton of the order detail.
class _OrderDetailShimmer extends StatelessWidget {
  const _OrderDetailShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: SingleChildScrollView(
      key: OrderDetailKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      child: const Column(
        children: <Widget>[
          AppShimmerBox(height: 32, width: 220),
          SizedBox(height: AppSpacing.lg),
          AppShimmerBox(height: 120),
          SizedBox(height: AppSpacing.lg),
          AppShimmerBox(height: 160),
          SizedBox(height: AppSpacing.lg),
          AppShimmerBox(height: 96),
        ],
      ),
    ),
  );
}
