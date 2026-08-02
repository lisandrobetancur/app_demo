part of com.demo.market.orders.ui.views.detail;

/// Data state of the order detail.
class _OrderDetailData extends ConsumerWidget {
  const _OrderDetailData();

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: OrderDetailKeys.confirmCancelDialog,
      title: 'orders.detail.cancel_title'.tr(),
      message: 'orders.detail.cancel_message'.tr(),
      confirmLabel: 'orders.detail.confirm'.tr(),
      cancelLabel: 'orders.detail.keep'.tr(),
      destructive: true,
    );
    if (confirmed) {
      await ref.read(orderDetailViewModelProvider.notifier).cancel();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderDetailState state = ref.watch(orderDetailViewModelProvider);
    final OrderDetailViewModel viewModel = ref.read(
      orderDetailViewModelProvider.notifier,
    );
    final Order order = state.order!;
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final String locale = context.locale.toString();
    String money(double value) => Formatters.formatPrice(
      currency.display(value),
      locale: locale,
      currencyCode: currency.code,
    );
    return SingleChildScrollView(
      key: OrderDetailKeys.state('data'),
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'orders.detail.order_number'.tr(
              namedArgs: <String, String>{'number': order.number},
            ),
            style: AppTypography.displayTitle,
          ),
          Text(
            Formatters.formatDateTime(order.createdAt, locale: locale),
            style: AppTypography.caption,
          ),
          AppSpacing.sectionGap,
          Text(
            'orders.detail.timeline_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          _OrderTimeline(status: order.status),
          AppSpacing.sectionGap,
          Text(
            'orders.detail.items_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final OrderItem item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.quantity} × ${item.name}',
                      style: AppTypography.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(money(item.lineTotal), style: AppTypography.body),
                ],
              ),
            ),
          AppSpacing.sectionGap,
          if (order.addressLabel.isNotEmpty) ...<Widget>[
            Text(
              'orders.detail.address_title'.tr(),
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(order.addressLabel, style: AppTypography.body),
            AppSpacing.sectionGap,
          ],
          Text(
            'orders.detail.payment_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            PaymentMethod.parse(order.paymentMethodDbValue).labelKey.tr(),
            style: AppTypography.body,
          ),
          AppSpacing.sectionGap,
          Text(
            'orders.detail.totals_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          _OrderTotalsRow(
            label: 'orders.detail.subtotal_label'.tr(),
            value: money(order.subtotal),
          ),
          _OrderTotalsRow(
            label: 'orders.detail.discount_label'.tr(),
            value: '-${money(order.discount)}',
          ),
          _OrderTotalsRow(
            label: 'orders.detail.tax_label'.tr(),
            value: money(order.tax),
          ),
          const Divider(),
          _OrderTotalsRow(
            label: 'orders.detail.total_label'.tr(),
            value: money(order.total),
            emphasized: true,
          ),
          AppSpacing.sectionGap,
          if (order.status.isCancellable)
            AppButton(
              key: OrderDetailKeys.cancelButton,
              label: 'orders.detail.cancel_button'.tr(),
              variant: AppButtonVariant.danger,
              isLoading: state.isCancelling,
              onPressed: () => _confirmCancel(context, ref),
              expand: true,
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: OrderDetailKeys.reorderButton,
            label: 'orders.detail.reorder_button'.tr(),
            icon: AppIcons.cart,
            variant: AppButtonVariant.secondary,
            isLoading: state.isReordering,
            onPressed: viewModel.reorder,
            expand: true,
          ),
        ],
      ),
    );
  }
}

/// One label/value row of the order totals.
class _OrderTotalsRow extends StatelessWidget {
  const _OrderTotalsRow({
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
