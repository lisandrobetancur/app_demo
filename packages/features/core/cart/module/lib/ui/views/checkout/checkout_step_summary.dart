part of com.demo.market.cart.ui.views.checkout;

/// Step 3: items, address, method and totals before confirming.
class _CheckoutStepSummary extends ConsumerWidget {
  const _CheckoutStepSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckoutState state = ref.watch(checkoutViewModelProvider);
    final CartState cartState = ref.watch(cartViewModelProvider);
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final String locale = context.locale.toString();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    String money(double value) => Formatters.formatPrice(
      currency.display(value),
      locale: locale,
      currencyCode: currency.code,
    );
    return ListView(
      padding: AppSpacing.pagePadding,
      children: <Widget>[
        if (state.errorKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              state.errorKey!.tr(),
              style: AppTypography.body.copyWith(color: scheme.error),
            ),
          ),
        Text(
          'cart.checkout.summary_items'.tr(),
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final CartLine line in cartState.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${line.quantity} × ${line.productName}',
                    style: AppTypography.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(money(line.lineTotal), style: AppTypography.body),
              ],
            ),
          ),
        AppSpacing.sectionGap,
        Text(
          'cart.checkout.summary_address'.tr(),
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.selectedAddress != null)
          Text(
            '${state.selectedAddress!.label} · '
            '${state.selectedAddress!.display}',
            style: AppTypography.body,
          ),
        AppSpacing.sectionGap,
        Text(
          'cart.checkout.summary_payment'.tr(),
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(state.paymentMethod.labelKey.tr(), style: AppTypography.body),
        AppSpacing.sectionGap,
        Text(
          'cart.checkout.summary_totals'.tr(),
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _CartTotalsSummary(),
      ],
    );
  }
}

/// Totals of the summary step, reusing the cart's reactive totals.
class _CartTotalsSummary extends ConsumerWidget {
  const _CartTotalsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CartTotals totals = ref.watch(
      cartViewModelProvider.select((CartState state) => state.totals),
    );
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final String locale = context.locale.toString();
    String money(double value) => Formatters.formatPrice(
      currency.display(value),
      locale: locale,
      currencyCode: currency.code,
    );
    return Column(
      children: <Widget>[
        _SummaryRow(
          label: 'cart.home.subtotal_label'.tr(),
          value: money(totals.subtotal),
        ),
        _SummaryRow(
          label: 'cart.home.discount_label'.tr(),
          value: '-${money(totals.discount)}',
        ),
        _SummaryRow(
          label: 'cart.home.tax_label'.tr(),
          value: money(totals.tax),
        ),
        const Divider(),
        _SummaryRow(
          label: 'cart.home.total_label'.tr(),
          value: money(totals.total),
          emphasized: true,
        ),
      ],
    );
  }
}

/// One label/value row of the summary totals.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = emphasized
        ? AppTypography.price
        : AppTypography.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
