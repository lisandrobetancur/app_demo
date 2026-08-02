part of com.demo.market.catalog.ui.views.favorites;

/// F14 · Favorites.
class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  static const String route = CatalogRoutes.favoritesPath;
  static const String name = CatalogRoutes.favoritesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FavoritesState state = ref.watch(favoritesViewModelProvider);
    final FavoritesViewModel viewModel = ref.read(
      favoritesViewModelProvider.notifier,
    );
    ref.listen<FavoritesState>(favoritesViewModelProvider, (
      FavoritesState? previous,
      FavoritesState next,
    ) {
      final String? event = next.lastEventKey;
      if (event != null && previous?.lastEventKey != event) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event.tr(namedArgs: <String, String>{'count': next.lastEventArg}),
            ),
          ),
        );
        viewModel.consumeEvent();
      }
    });
    return AppScaffold(
      key: FavoritesKeys.view,
      title: 'catalog.favorites.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: <Widget>[
        if (state.status.isData && state.available.isNotEmpty)
          TextButton.icon(
            key: FavoritesKeys.moveAllToCartButton,
            onPressed: state.isMovingAll ? null : viewModel.moveAllToCart,
            icon: const Icon(AppIcons.cart, size: 18),
            label: Text('catalog.favorites.move_all_button'.tr()),
          ),
      ],
      body: switch (state.status) {
        ViewStatus.loading => const _FavoritesShimmer(),
        ViewStatus.data => const _FavoritesData(),
        ViewStatus.empty => const _FavoritesEmpty(),
        ViewStatus.error => const _FavoritesError(),
      },
    );
  }
}
