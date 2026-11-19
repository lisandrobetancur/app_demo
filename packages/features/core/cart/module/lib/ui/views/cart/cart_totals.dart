part of com.demo.market.cart.ui.views.cart;

/// Reactive totals block: subtotal, discount, 19% VAT and total.
class _CartTotals extends ConsumerWidget {
  const _CartTotals();

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
        _TotalsRow(
          rowKey: CartKeys.subtotalText,
          valueSemanticsId: CartSemanticIds.subtotalText,
          label: 'cart.home.subtotal_label'.tr(),
          value: money(totals.subtotal),
        ),
        _TotalsRow(
          rowKey: CartKeys.discountText,
          valueSemanticsId: CartSemanticIds.discountText,
          label: 'cart.home.discount_label'.tr(),
          value: '-${money(totals.discount)}',
        ),
        _TotalsRow(
          rowKey: CartKeys.taxText,
          valueSemanticsId: CartSemanticIds.taxText,
          label: 'cart.home.tax_label'.tr(),
          value: money(totals.tax),
        ),
        const Divider(),
        _TotalsRow(
          rowKey: CartKeys.totalText,
          valueSemanticsId: CartSemanticIds.totalText,
          label: 'cart.home.total_label'.tr(),
          value: money(totals.total),
          emphasized: true,
        ),
      ],
    );
  }
}

/// One label/value row of the totals block.
class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.rowKey,
    required this.label,
    required this.value,
    required this.valueSemanticsId,
    this.emphasized = false,
  });

  final Key rowKey;
  final String label;
  final String value;
  final bool emphasized;

  /// On the value alone, so a test reads the amount without its label.
  final String valueSemanticsId;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = emphasized
        ? AppTypography.price
        : AppTypography.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        key: rowKey,
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          // A node of its own, holding just the amount.
          Semantics(
            container: true,
            identifier: valueSemanticsId,
            child: Text(value, style: style),
          ),
        ],
      ),
    );
  }
}
