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
          label: 'cart.home.subtotal_label'.tr(),
          value: money(totals.subtotal),
        ),
        _TotalsRow(
          rowKey: CartKeys.discountText,
          label: 'cart.home.discount_label'.tr(),
          value: '-${money(totals.discount)}',
        ),
        _TotalsRow(
          rowKey: CartKeys.taxText,
          label: 'cart.home.tax_label'.tr(),
          value: money(totals.tax),
        ),
        const Divider(),
        _TotalsRow(
          rowKey: CartKeys.totalText,
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
    this.emphasized = false,
  });

  final Key rowKey;
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
        key: rowKey,
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
