part of com.demo.market.orders.ui.views.detail;

/// Error state with retry.
class _OrderDetailError extends ConsumerWidget {
  const _OrderDetailError({required this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: OrderDetailKeys.state('error'),
    icon: AppIcons.error,
    title: 'orders.detail.error_title'.tr(),
    actionLabel: 'orders.detail.retry_button'.tr(),
    onAction: orderId == null
        ? null
        : () => ref.read(orderDetailViewModelProvider.notifier).load(orderId!),
  );
}
