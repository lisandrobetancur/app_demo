part of com.demo.market.orders.ui.views.list;

/// F13 · Orders history with status filter and number search.
class OrdersListView extends ConsumerWidget {
  const OrdersListView({super.key});

  static const String route = OrdersRoutes.listPath;
  static const String name = OrdersRoutes.listName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrdersListState state = ref.watch(ordersListViewModelProvider);
    final OrdersListViewModel viewModel = ref.read(
      ordersListViewModelProvider.notifier,
    );
    return AppScaffold(
      key: OrdersListKeys.view,
      title: 'orders.list.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: AppTextField(
              key: OrdersListKeys.searchInput,
              label: 'orders.list.search_hint'.tr(),
              prefixIcon: AppIcons.search,
              onChanged: viewModel.setQuery,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    key: OrdersListKeys.statusFilter('ALL'),
                    label: Text('orders.list.filter_all'.tr()),
                    selected: state.statusFilter == null,
                    onSelected: (bool _) => viewModel.setStatusFilter(null),
                  ),
                ),
                for (final OrderStatus status in OrderStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      key: OrdersListKeys.statusFilter(status.dbValue),
                      label: Text(status.labelKey.tr()),
                      selected: state.statusFilter == status,
                      onSelected: (bool _) => viewModel.setStatusFilter(status),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              ViewStatus.loading => const _OrdersListShimmer(),
              ViewStatus.data => const _OrdersListData(),
              ViewStatus.empty => const _OrdersListEmpty(),
              ViewStatus.error => const _OrdersListError(),
            },
          ),
        ],
      ),
    );
  }
}
