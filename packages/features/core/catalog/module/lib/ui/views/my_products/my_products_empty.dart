part of com.demo.market.catalog.ui.views.my_products;

/// Empty state with a publish CTA.
class _MyProductsEmpty extends ConsumerWidget {
  const _MyProductsEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: MyProductsKeys.state('empty'),
    icon: AppIcons.catalog,
    title: 'catalog.my_products.empty_title'.tr(),
    message: 'catalog.my_products.empty_message'.tr(),
    actionLabel: 'catalog.my_products.publish_button'.tr(),
    onAction: ref.read(myProductsViewModelProvider.notifier).goToCreate,
  );
}
