part of com.demo.market.catalog.ui.views.my_products;

/// Data state: own publications with status, actions and quick stock edit.
class _MyProductsData extends ConsumerWidget {
  const _MyProductsData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyProductsState state = ref.watch(myProductsViewModelProvider);
    return RefreshIndicator(
      onRefresh: ref.read(myProductsViewModelProvider.notifier).load,
      child: ListView.separated(
        key: MyProductsKeys.state('data'),
        padding: AppSpacing.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.products.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Product product = state.products[index];
          return _MyProductTile(
            key: MyProductsKeys.item(product.id),
            product: product,
            isBusy: state.busyProductId == product.id,
          );
        },
      ),
    );
  }
}

/// One publication row with owner actions.
class _MyProductTile extends ConsumerWidget {
  const _MyProductTile({
    required this.product,
    required this.isBusy,
    super.key,
  });

  final Product product;
  final bool isBusy;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: MyProductsKeys.confirmDeleteDialog,
      title: 'catalog.my_products.delete_title'.tr(),
      message: 'catalog.my_products.delete_message'.tr(),
      confirmLabel: 'catalog.my_products.confirm'.tr(),
      cancelLabel: 'catalog.my_products.cancel'.tr(),
      destructive: true,
    );
    if (confirmed) {
      await ref
          .read(myProductsViewModelProvider.notifier)
          .deleteProduct(product);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyProductsViewModel viewModel = ref.read(
      myProductsViewModelProvider.notifier,
    );
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  product.name,
                  style: AppTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: product.status.labelKey.tr(),
                tone: product.status.isActive
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          PriceTag(
            value: currency.display(product.price),
            locale: context.locale.toString(),
            currencyCode: currency.code,
            size: PriceTagSize.small,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Text(
                'catalog.my_products.stock_label'.tr(),
                style: AppTypography.caption,
              ),
              const SizedBox(width: AppSpacing.sm),
              QuantityStepper(
                key: MyProductsKeys.stockQuickEdit(product.id),
                value: product.stock,
                min: 0,
                max: 999,
                enabled: !isBusy,
                onChanged: (int stock) => viewModel.adjustStock(product, stock),
              ),
              const Spacer(),
              IconButton(
                key: MyProductsKeys.editButton(product.id),
                icon: const Icon(AppIcons.edit),
                tooltip: 'catalog.detail.edit_button'.tr(),
                onPressed: isBusy ? null : () => viewModel.goToEdit(product.id),
              ),
              IconButton(
                key: MyProductsKeys.toggleStatusButton(product.id),
                icon: Icon(
                  product.status.isPaused ? AppIcons.play : AppIcons.pause,
                ),
                tooltip: product.status.isPaused
                    ? 'catalog.my_products.activate_button'.tr()
                    : 'catalog.my_products.pause_button'.tr(),
                onPressed: isBusy
                    ? null
                    : () => viewModel.toggleStatus(product),
              ),
              IconButton(
                key: MyProductsKeys.deleteButton(product.id),
                icon: Icon(
                  AppIcons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: 'catalog.my_products.delete_button'.tr(),
                onPressed: isBusy ? null : () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
