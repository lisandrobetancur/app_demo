part of com.demo.market.orders.ui.views.list;

/// Loading skeleton of the orders history.
class _OrdersListShimmer extends StatelessWidget {
  const _OrdersListShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      key: OrdersListKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          const AppShimmerBox(height: 112),
    ),
  );
}
