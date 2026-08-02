part of com.demo.market.catalog.ui.views.list;

/// Loading skeleton of the catalog list.
class _ListShimmer extends StatelessWidget {
  const _ListShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      key: CatalogListKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      itemCount: 6,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          const AppShimmerBox(height: 104),
    ),
  );
}
