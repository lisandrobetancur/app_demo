part of com.demo.market.catalog.ui.views.my_products;

/// Error state with retry.
class _MyProductsError extends ConsumerWidget {
  const _MyProductsError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: MyProductsKeys.state('error'),
    icon: AppIcons.error,
    title: 'catalog.my_products.error_title'.tr(),
    actionLabel: 'catalog.my_products.retry_button'.tr(),
    onAction: ref.read(myProductsViewModelProvider.notifier).load,
  );
}
