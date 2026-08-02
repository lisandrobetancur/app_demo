part of com.demo.market.catalog.ui.views.list;

/// Empty state of the catalog list (no products for the current filters).
class _ListEmpty extends ConsumerWidget {
  const _ListEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasFilters = ref
        .watch(listViewModelProvider)
        .filters
        .hasAnyFilter;
    return EmptyState(
      key: CatalogListKeys.state('empty'),
      icon: AppIcons.catalog,
      title: 'catalog.list.empty_title'.tr(),
      message: 'catalog.list.empty_message'.tr(),
      actionLabel: hasFilters ? 'catalog.list.clear_filters'.tr() : null,
      onAction: hasFilters
          ? ref.read(listViewModelProvider.notifier).clearFilters
          : null,
    );
  }
}
