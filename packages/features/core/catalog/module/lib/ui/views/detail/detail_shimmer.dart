part of com.demo.market.catalog.ui.views.detail;

/// Loading skeleton of the product detail.
class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: SingleChildScrollView(
      key: ProductDetailKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppShimmerBox(height: 220),
          SizedBox(height: AppSpacing.lg),
          AppShimmerBox(height: 28, width: 240),
          SizedBox(height: AppSpacing.sm),
          AppShimmerBox(height: 20, width: 160),
          SizedBox(height: AppSpacing.lg),
          AppShimmerBox(height: 96),
          SizedBox(height: AppSpacing.lg),
          AppShimmerBox(height: 48),
        ],
      ),
    ),
  );
}
