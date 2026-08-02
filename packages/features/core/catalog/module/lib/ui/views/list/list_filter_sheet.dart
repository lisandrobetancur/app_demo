part of com.demo.market.catalog.ui.views.list;

/// Filter bottom sheet: categories, price range, condition and stock.
class _ListFilterSheet extends ConsumerWidget {
  const _ListFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ListState state = ref.watch(listViewModelProvider);
    final ListViewModel viewModel = ref.read(listViewModelProvider.notifier);
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final RangeValues priceRange = RangeValues(
      state.filters.minPrice ?? 0,
      state.filters.maxPrice ?? CatalogLimits.priceRangeMax,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'catalog.list.filters_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'catalog.list.category_label'.tr(),
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final Category category in state.categories)
                FilterChip(
                  key: CatalogListKeys.categoryFilter(category.code),
                  label: Text(category.labelKey.tr()),
                  selected: state.filters.categoryIds.contains(category.id),
                  onSelected: (bool _) => viewModel.toggleCategory(category.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'catalog.list.price_range_label'.tr(),
            style: AppTypography.cardTitle,
          ),
          RangeSlider(
            key: CatalogListKeys.priceRangeSlider,
            values: priceRange,
            max: CatalogLimits.priceRangeMax,
            divisions: 30,
            labels: RangeLabels(
              currency.display(priceRange.start).toStringAsFixed(0),
              currency.display(priceRange.end).toStringAsFixed(0),
            ),
            onChanged: (RangeValues values) {
              final bool isFullRange =
                  values.start <= 0 &&
                  values.end >= CatalogLimits.priceRangeMax;
              if (isFullRange) {
                viewModel.setPriceRange(null, null);
              } else {
                viewModel.setPriceRange(values.start, values.end);
              }
            },
          ),
          Text(
            'catalog.list.condition_label'.tr(),
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final ProductCondition condition in ProductCondition.values)
                FilterChip(
                  key: CatalogListKeys.conditionFilter(condition.dbValue),
                  label: Text(condition.labelKey.tr()),
                  selected: state.filters.conditions.contains(condition),
                  onSelected: (bool _) => viewModel.toggleCondition(condition),
                ),
            ],
          ),
          SwitchListTile(
            value: state.filters.onlyInStock,
            contentPadding: EdgeInsets.zero,
            title: Text('catalog.list.only_in_stock'.tr()),
            onChanged: viewModel.setOnlyInStock,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
