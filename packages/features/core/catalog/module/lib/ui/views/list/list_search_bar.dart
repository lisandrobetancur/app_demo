part of com.demo.market.catalog.ui.views.list;

/// Search input with 300 ms debounce and history-based suggestions.
class _ListSearchBar extends ConsumerWidget {
  const _ListSearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ListState state = ref.watch(listViewModelProvider);
    final ListViewModel viewModel = ref.read(listViewModelProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppTextField(
          key: CatalogListKeys.searchInput,
          label: 'catalog.list.search_hint'.tr(),
          prefixIcon: AppIcons.search,
          onChanged: viewModel.setSearchTerm,
        ),
        if (state.suggestions.isNotEmpty && state.filters.query.isEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (int index = 0; index < state.suggestions.length; index++)
                ActionChip(
                  key: CatalogListKeys.searchSuggestion(index + 1),
                  avatar: const Icon(AppIcons.search, size: 14),
                  label: Text(state.suggestions[index]),
                  onPressed: () =>
                      viewModel.applySuggestion(state.suggestions[index]),
                ),
            ],
          ),
      ],
    );
  }
}
