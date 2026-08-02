part of com.demo.market.catalog.ui.views.favorites;

/// Loading skeleton of the favorites list.
class _FavoritesShimmer extends StatelessWidget {
  const _FavoritesShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      key: FavoritesKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          const AppShimmerBox(height: 148),
    ),
  );
}
