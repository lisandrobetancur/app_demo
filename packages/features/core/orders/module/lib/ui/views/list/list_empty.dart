part of com.demo.market.orders.ui.views.list;

/// Empty state of the orders history.
class _OrdersListEmpty extends StatelessWidget {
  const _OrdersListEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: OrdersListKeys.state('empty'),
    icon: AppIcons.orders,
    title: 'orders.list.empty_title'.tr(),
    message: 'orders.list.empty_message'.tr(),
  );
}
