part of com.demo.market.orders.ui.views.detail;

/// Not-found state (unknown deep-linked order id).
class _OrderDetailEmpty extends StatelessWidget {
  const _OrderDetailEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: OrderDetailKeys.state('empty'),
    icon: AppIcons.emptyBox,
    title: 'orders.detail.not_found_title'.tr(),
    message: 'orders.detail.not_found_message'.tr(),
  );
}
