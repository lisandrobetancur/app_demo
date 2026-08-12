part of com.demo.market.cart.ui.views.cart;

/// Data state: lines + coupon + totals + checkout CTA.
class _CartData extends ConsumerWidget {
  const _CartData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CartState state = ref.watch(cartViewModelProvider);
    final CartViewModel viewModel = ref.read(cartViewModelProvider.notifier);
    return Column(
      key: CartKeys.state('data'),
      children: <Widget>[
        Expanded(
          child: ListView.separated(
            key: CartKeys.itemsList,
            padding: AppSpacing.pagePadding,
            itemCount: state.lines.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final CartLine line = state.lines[index];
              return _CartLineTile(key: CartKeys.item(line.id), line: line);
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _CartCoupon(),
                const SizedBox(height: AppSpacing.md),
                const _CartTotals(),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  key: CartKeys.checkoutButton,
                  label: 'cart.home.checkout_button'.tr(),
                  onPressed: state.canCheckout ? viewModel.goToCheckout : null,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One cart line: thumbnail, unit price, stepper bounded by stock, remove.
class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.line, super.key});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CartViewModel viewModel = ref.read(cartViewModelProvider.notifier);
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: AppRadius.card,
            child: SizedBox(
              width: 56,
              height: 56,
              child: line.imageBytes == null
                  ? ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        AppIcons.forCategoryCode(line.categoryCode),
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Image.memory(line.imageBytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.productName,
                  style: AppTypography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  Formatters.formatPrice(
                    currency.display(line.unitPrice),
                    locale: context.locale.toString(),
                    currencyCode: currency.code,
                  ),
                  style: AppTypography.caption,
                ),
                if (line.isUnavailable)
                  Text(
                    'cart.home.unavailable_notice'.tr(),
                    style: AppTypography.caption.copyWith(color: scheme.error),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    QuantityStepper(
                      value: line.quantity,
                      max: line.stock,
                      decreaseKey: CartKeys.decreaseQuantityButton(line.id),
                      increaseKey: CartKeys.increaseQuantityButton(line.id),
                      onChanged: (int quantity) =>
                          viewModel.setQuantity(line, quantity),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.formatPrice(
                        currency.display(line.lineTotal),
                        locale: context.locale.toString(),
                        currencyCode: currency.code,
                      ),
                      style: AppTypography.cardTitle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: CartKeys.removeItemButton(line.id),
            icon: const Icon(AppIcons.delete),
            tooltip: 'cart.home.remove_item'.tr(),
            onPressed: () => viewModel.removeLine(line),
          ),
        ],
      ),
    );
  }
}
