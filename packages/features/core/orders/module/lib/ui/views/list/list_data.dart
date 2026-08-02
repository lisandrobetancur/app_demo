part of com.demo.market.orders.ui.views.list;

/// Data state: order rows, newest first.
class _OrdersListData extends ConsumerWidget {
  const _OrdersListData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrdersListState state = ref.watch(ordersListViewModelProvider);
    final OrdersListViewModel viewModel = ref.read(
      ordersListViewModelProvider.notifier,
    );
    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView.separated(
        key: OrdersListKeys.state('data'),
        padding: AppSpacing.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.orders.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Order order = state.orders[index];
          return _OrderTile(
            key: OrdersListKeys.item(order.id),
            order: order,
            onTap: () => viewModel.openDetail(order.id),
          );
        },
      ),
    );
  }
}

/// One order row.
class _OrderTile extends ConsumerWidget {
  const _OrderTile({required this.order, required this.onTap, super.key});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final String locale = context.locale.toString();
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'orders.detail.order_number'.tr(
                    namedArgs: <String, String>{'number': order.number},
                  ),
                  style: AppTypography.cardTitle,
                ),
              ),
              StatusBadge(
                label: order.status.labelKey.tr(),
                tone: switch (order.status) {
                  OrderStatus.created => StatusBadgeTone.info,
                  OrderStatus.paid => StatusBadgeTone.info,
                  OrderStatus.shipped => StatusBadgeTone.warning,
                  OrderStatus.delivered => StatusBadgeTone.success,
                  OrderStatus.cancelled => StatusBadgeTone.error,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Formatters.formatDate(order.createdAt, locale: locale)} · '
            '${'orders.list.items_count'.tr(namedArgs: <String, String>{'count': '${order.items.length}'})}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.formatPrice(
              currency.display(order.total),
              locale: locale,
              currencyCode: currency.code,
            ),
            style: AppTypography.price.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
