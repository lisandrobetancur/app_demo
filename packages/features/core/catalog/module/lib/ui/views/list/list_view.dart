part of com.demo.market.catalog.ui.views.list;

/// F07 · Catalog list with search, filters, sorting and infinite scroll.
class CatalogListView extends ConsumerWidget {
  const CatalogListView({super.key});

  static const String route = CatalogRoutes.listPath;
  static const String name = CatalogRoutes.listName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ListState state = ref.watch(listViewModelProvider);
    final ListViewModel viewModel = ref.read(listViewModelProvider.notifier);
    return AppScaffold(
      key: CatalogListKeys.view,
      title: 'catalog.list.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: <Widget>[
        IconButton(
          key: CatalogListKeys.filterButton,
          icon: Badge.count(
            count: state.filters.activeCount,
            isLabelVisible: state.filters.hasAnyFilter,
            child: const Icon(AppIcons.filter),
          ),
          tooltip: 'catalog.list.filters_title'.tr(),
          onPressed: () => _openFilterSheet(context),
        ),
      ],
      body: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: _ListSearchBar(),
          ),
          _ActiveFiltersBar(state: state, viewModel: viewModel),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: <Widget>[
                Text(
                  'catalog.list.results_count'.tr(
                    namedArgs: <String, String>{
                      'count': '${state.resultsCount}',
                    },
                  ),
                  key: CatalogListKeys.resultsCountText,
                  style: AppTypography.caption,
                ),
                const Spacer(),
                const _SortMenu(),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              ViewStatus.loading => const _ListShimmer(),
              ViewStatus.data => const _ListData(),
              ViewStatus.empty => const _ListEmpty(),
              ViewStatus.error => const _ListError(),
            },
          ),
        ],
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    AppBottomSheet.show<void>(
      context,
      sheetKey: CatalogListKeys.filterSheet,
      child: const _ListFilterSheet(),
    );
  }
}

/// Sort selector (popup menu with per-option keys).
class _SortMenu extends ConsumerWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProductSort current = ref.watch(listViewModelProvider).filters.sort;
    return PopupMenuButton<ProductSort>(
      key: CatalogListKeys.sortDropdown,
      initialValue: current,
      onSelected: ref.read(listViewModelProvider.notifier).setSort,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ProductSort>>[
        for (final ProductSort sort in ProductSort.values)
          PopupMenuItem<ProductSort>(
            key: CatalogListKeys.sortOption(sort.name),
            value: sort,
            child: Text(sort.labelKey.tr()),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(AppIcons.sort, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(current.labelKey.tr(), style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

/// Chips of the currently active filters.
class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({required this.state, required this.viewModel});

  final ListState state;
  final ListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final List<FilterChipItem> chips = <FilterChipItem>[
      for (final Category category in state.categories)
        if (state.filters.categoryIds.contains(category.id))
          FilterChipItem(
            chipKey: CatalogListKeys.activeFilterChip(category.id),
            label: category.labelKey.tr(),
            onRemoved: () => viewModel.toggleCategory(category.id),
          ),
      for (final ProductCondition condition in state.filters.conditions)
        FilterChipItem(
          chipKey: CatalogListKeys.activeFilterChip(condition.dbValue),
          label: condition.labelKey.tr(),
          onRemoved: () => viewModel.toggleCondition(condition),
        ),
      if (state.filters.hasPriceRange)
        FilterChipItem(
          chipKey: CatalogListKeys.activeFilterChip('price'),
          label: 'catalog.list.filter_price_chip'.tr(),
          onRemoved: () => viewModel.setPriceRange(null, null),
        ),
      if (state.filters.onlyInStock)
        FilterChipItem(
          chipKey: CatalogListKeys.activeFilterChip('stock'),
          label: 'catalog.list.filter_stock_chip'.tr(),
          onRemoved: () => viewModel.setOnlyInStock(false),
        ),
    ];
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FilterChipBar(
        chips: chips,
        clearAllLabel: 'catalog.list.clear_filters'.tr(),
        clearAllKey: CatalogListKeys.clearFiltersButton,
        onClearAll: viewModel.clearFilters,
      ),
    );
  }
}
