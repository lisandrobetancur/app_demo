part of com.demo.market.catalog.ui.views.list;

/// Data state: product list with infinite scroll (20 by 20).
class _ListData extends ConsumerWidget {
  const _ListData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ListState state = ref.watch(listViewModelProvider);
    final ListViewModel viewModel = ref.read(listViewModelProvider.notifier);
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final String locale = context.locale.toString();
    return NotificationListener<ScrollNotification>(
      key: CatalogListKeys.state('data'),
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.extentAfter < 300) {
          viewModel.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: viewModel.loadProducts,
        child: ListView.separated(
          key: CatalogListKeys.productsList,
          padding: AppSpacing.pagePadding,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (BuildContext context, int index) {
            if (index >= state.products.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final Product product = state.products[index];
            return _CatalogProductTile(
              key: CatalogListKeys.productItem(product.id),
              product: product,
              locale: locale,
              currency: currency,
              isFavorite: state.favoriteIds.contains(product.id),
              onTap: () => viewModel.openDetail(product.id),
              onFavoriteToggle: () => viewModel.toggleFavorite(product.id),
            );
          },
        ),
      ),
    );
  }
}

/// One product row of the catalog list, built on the shared [ProductCard].
class _CatalogProductTile extends StatelessWidget {
  const _CatalogProductTile({
    required this.product,
    required this.locale,
    required this.currency,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    super.key,
  });

  final Product product;
  final String locale;
  final DisplayCurrency currency;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) => Semantics(
    label: product.name,
    button: true,
    child: ProductCard(
      name: product.name,
      subtitle:
          '${'catalog.categories.${product.categoryCode.toLowerCase()}'.tr()}'
          ' · ${product.condition.labelKey.tr()}',
      priceValue: currency.display(product.price),
      locale: locale,
      currencyCode: currency.code,
      categoryIcon: AppIcons.forCategoryCode(product.categoryCode),
      imageBytes: product.imageBytes,
      rating: product.ratingAverage,
      ratingCount: product.ratingCount,
      stockText: product.isOutOfStock
          ? 'catalog.list.out_of_stock'.tr()
          : 'catalog.list.stock_label'.tr(
              namedArgs: <String, String>{'count': '${product.stock}'},
            ),
      outOfStock: product.isOutOfStock,
      onTap: onTap,
      trailing: IconButton(
        icon: Icon(
          isFavorite ? AppIcons.favorite : AppIcons.favoriteOutline,
          color: isFavorite
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        tooltip: 'catalog.detail.favorite_label'.tr(),
        onPressed: onFavoriteToggle,
      ),
    ),
  );
}
