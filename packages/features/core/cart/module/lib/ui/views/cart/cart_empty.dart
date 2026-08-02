part of com.demo.market.cart.ui.views.cart;

/// Empty state with a catalog CTA.
class _CartEmpty extends ConsumerWidget {
  const _CartEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: CartKeys.state('empty'),
    icon: AppIcons.cart,
    title: 'cart.home.empty_title'.tr(),
    message: 'cart.home.empty_message'.tr(),
    actionLabel: 'cart.home.go_to_catalog_button'.tr(),
    onAction: ref.read(cartViewModelProvider.notifier).goToCatalog,
  );
}
