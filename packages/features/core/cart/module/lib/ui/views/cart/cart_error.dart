part of com.demo.market.cart.ui.views.cart;

/// Error state with retry.
class _CartError extends ConsumerWidget {
  const _CartError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: CartKeys.state('error'),
    icon: AppIcons.error,
    title: 'cart.home.error_title'.tr(),
    actionLabel: 'cart.home.retry_button'.tr(),
    onAction: ref.read(cartViewModelProvider.notifier).load,
  );
}
