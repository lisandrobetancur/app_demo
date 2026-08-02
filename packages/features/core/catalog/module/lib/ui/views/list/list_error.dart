part of com.demo.market.catalog.ui.views.list;

/// Error state of the catalog list with retry.
class _ListError extends ConsumerWidget {
  const _ListError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: CatalogListKeys.state('error'),
    icon: AppIcons.error,
    title: 'catalog.list.error_title'.tr(),
    actionLabel: 'catalog.list.retry_button'.tr(),
    onAction: ref.read(listViewModelProvider.notifier).loadProducts,
  );
}
