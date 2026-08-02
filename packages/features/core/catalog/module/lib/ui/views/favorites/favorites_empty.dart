part of com.demo.market.catalog.ui.views.favorites;

/// Illustrated empty state of favorites.
class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: FavoritesKeys.state('empty'),
    icon: AppIcons.favoriteOutline,
    title: 'catalog.favorites.empty_title'.tr(),
    message: 'catalog.favorites.empty_message'.tr(),
  );
}
