part of com.demo.market.orders.ui.views.list;

/// Error state with retry.
class _OrdersListError extends ConsumerWidget {
  const _OrdersListError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: OrdersListKeys.state('error'),
    icon: AppIcons.error,
    title: 'orders.list.error_title'.tr(),
    actionLabel: 'orders.list.retry_button'.tr(),
    onAction: ref.read(ordersListViewModelProvider.notifier).load,
  );
}
