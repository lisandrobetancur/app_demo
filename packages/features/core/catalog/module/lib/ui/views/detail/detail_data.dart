part of com.demo.market.catalog.ui.views.detail;

/// Data state of the product detail.
class _DetailData extends ConsumerWidget {
  const _DetailData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DetailState state = ref.watch(detailViewModelProvider);
    final DetailViewModel viewModel = ref.read(
      detailViewModelProvider.notifier,
    );
    final Product product = state.product!;
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final String? viewerId = ref.watch(authSessionProvider)?.id;
    final bool isOwner = state.isOwnedBy(viewerId);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: ProductDetailKeys.state('data'),
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DetailImage(product: product),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(product.name, style: AppTypography.displayTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          'catalog.categories.'
                                  '${product.categoryCode.toLowerCase()}'
                              .tr(),
                          style: AppTypography.caption,
                        ),
                        Text(
                          product.condition.labelKey.tr(),
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        RatingStars(
                          rating: product.ratingAverage ?? 0,
                          count: product.ratingCount,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'catalog.detail.favorite_label'.tr(),
                button: true,
                child: IconButton(
                  key: ProductDetailKeys.favoriteToggleButton,
                  icon: Icon(
                    state.isFavorite
                        ? AppIcons.favorite
                        : AppIcons.favoriteOutline,
                    color: state.isFavorite
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                  onPressed: viewModel.toggleFavorite,
                ),
              ),
              Semantics(
                label: 'catalog.detail.share_label'.tr(),
                button: true,
                child: IconButton(
                  key: ProductDetailKeys.shareProductButton,
                  icon: const Icon(AppIcons.share),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: viewModel.shareLink()),
                    );
                    viewModel.markShared();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PriceTag(
            key: ProductDetailKeys.priceText,
            value: currency.display(product.price),
            locale: context.locale.toString(),
            currencyCode: currency.code,
            size: PriceTagSize.large,
          ),
          Text(
            product.isOutOfStock
                ? 'catalog.list.out_of_stock'.tr()
                : 'catalog.list.stock_label'.tr(
                    namedArgs: <String, String>{'count': '${product.stock}'},
                  ),
            key: ProductDetailKeys.stockText,
            style: AppTypography.body.copyWith(
              color: product.isOutOfStock
                  ? scheme.error
                  : scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.sectionGap,
          Text(
            'catalog.detail.description_label'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(product.description, style: AppTypography.body),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${'catalog.detail.seller_label'.tr()}: ${product.ownerName}',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.sectionGap,
          if (isOwner)
            _OwnerActions(viewModel: viewModel)
          else
            _BuyerActions(state: state, viewModel: viewModel),
          AppSpacing.sectionGap,
          const _DetailReviews(),
        ],
      ),
    );
  }
}

/// Product image or category placeholder.
class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      key: ProductDetailKeys.image,
      borderRadius: AppRadius.card,
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: product.imageBytes == null
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  AppIcons.forCategoryCode(product.categoryCode),
                  size: 96,
                  color: scheme.onSurfaceVariant,
                ),
              )
            : Image.memory(product.imageBytes!, fit: BoxFit.cover),
      ),
    );
  }
}

/// Buy-side actions: quantity + add to cart.
class _BuyerActions extends StatelessWidget {
  const _BuyerActions({required this.state, required this.viewModel});

  final DetailState state;
  final DetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final Product product = state.product!;
    return Row(
      children: <Widget>[
        if (!product.isOutOfStock)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: QuantityStepper(
              key: ProductDetailKeys.quantityStepper,
              value: state.quantity,
              max: product.stock,
              decreaseKey: ProductDetailKeys.quantityDecreaseButton,
              increaseKey: ProductDetailKeys.quantityIncreaseButton,
              onChanged: viewModel.setQuantity,
            ),
          ),
        Expanded(
          child: AppButton(
            key: ProductDetailKeys.addToCartButton,
            label: product.isOutOfStock
                ? 'catalog.detail.out_of_stock_cta'.tr()
                : 'catalog.detail.add_to_cart_button'.tr(),
            icon: AppIcons.cart,
            isLoading: state.isAddingToCart,
            onPressed: product.isOutOfStock ? null : viewModel.addToCart,
            expand: true,
          ),
        ),
      ],
    );
  }
}

/// Sell-side actions shown to the owner instead of the purchase CTA.
class _OwnerActions extends StatelessWidget {
  const _OwnerActions({required this.viewModel});

  final DetailViewModel viewModel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(
        'catalog.detail.own_product_notice'.tr(),
        style: AppTypography.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        key: ProductDetailKeys.editProductButton,
        label: 'catalog.detail.edit_button'.tr(),
        icon: AppIcons.edit,
        variant: AppButtonVariant.secondary,
        onPressed: viewModel.goToEdit,
        expand: true,
      ),
    ],
  );
}
