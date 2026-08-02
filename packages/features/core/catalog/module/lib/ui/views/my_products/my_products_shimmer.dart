part of com.demo.market.catalog.ui.views.my_products;

/// Loading skeleton of the my-publications list.
class _MyProductsShimmer extends StatelessWidget {
  const _MyProductsShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      key: MyProductsKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          const AppShimmerBox(height: 132),
    ),
  );
}
