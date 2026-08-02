part of com.demo.market.catalog.ui.views.favorites;

/// Error state with retry.
class _FavoritesError extends ConsumerWidget {
  const _FavoritesError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: FavoritesKeys.state('error'),
    icon: AppIcons.error,
    title: 'catalog.favorites.error_title'.tr(),
    actionLabel: 'catalog.favorites.retry_button'.tr(),
    onAction: ref.read(favoritesViewModelProvider.notifier).load,
  );
}
