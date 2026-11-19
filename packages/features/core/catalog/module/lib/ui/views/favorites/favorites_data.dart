part of com.demo.market.catalog.ui.views.favorites;

/// Data state: favorite products with availability notices.
class _FavoritesData extends ConsumerWidget {
  const _FavoritesData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FavoritesState state = ref.watch(favoritesViewModelProvider);
    final FavoritesViewModel viewModel = ref.read(
      favoritesViewModelProvider.notifier,
    );
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: SemanticRegion(
        identifier: FavoritesSemanticIds.state('data'),
        child: ListView.separated(
          key: FavoritesKeys.state('data'),
          padding: AppSpacing.pagePadding,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.products.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (BuildContext context, int index) {
            final Product product = state.products[index];
            final bool unavailable = !product.status.isActive;
            final bool canMove =
                product.status.isActive && !product.isOutOfStock;
            return SemanticRegion(
              identifier: FavoritesSemanticIds.item(product.id),
              child: Column(
                key: FavoritesKeys.item(product.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ProductCard(
                    semanticsId: FavoritesSemanticIds.productCard(product.id),
                    name: product.name,
                    subtitle:
                        '${'catalog.categories.${product.categoryCode.toLowerCase()}'.tr()}'
                        ' · ${product.condition.labelKey.tr()}',
                    priceValue: currency.display(product.price),
                    locale: context.locale.toString(),
                    currencyCode: currency.code,
                    categoryIcon: AppIcons.forCategoryCode(
                      product.categoryCode,
                    ),
                    imageBytes: product.imageBytes,
                    rating: product.ratingAverage,
                    ratingCount: product.ratingCount,
                    outOfStock: product.isOutOfStock,
                    badge: unavailable
                        ? StatusBadge(
                            label: 'catalog.favorites.removed_by_owner_notice'
                                .tr(),
                            tone: StatusBadgeTone.error,
                          )
                        : product.isOutOfStock
                        ? StatusBadge(
                            label: 'catalog.favorites.out_of_stock_notice'.tr(),
                            tone: StatusBadgeTone.warning,
                          )
                        : null,
                    onTap: unavailable
                        ? null
                        : () => viewModel.openDetail(product.id),
                    trailing: IconButton(
                      key: FavoritesKeys.toggleButton(product.id),
                      icon: Semantics(
                        identifier: FavoritesSemanticIds.toggleButton(
                          product.id,
                        ),
                        child: Icon(
                          AppIcons.favorite,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      tooltip: 'catalog.detail.favorite_label'.tr(),
                      onPressed: () => viewModel.removeFavorite(product),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    key: FavoritesKeys.moveToCartButton(product.id),
                    semanticsId: FavoritesSemanticIds.moveToCartButton(
                      product.id,
                    ),
                    label: 'catalog.favorites.move_to_cart_button'.tr(),
                    icon: AppIcons.cart,
                    variant: AppButtonVariant.secondary,
                    onPressed: canMove
                        ? () => viewModel.moveToCart(product)
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
