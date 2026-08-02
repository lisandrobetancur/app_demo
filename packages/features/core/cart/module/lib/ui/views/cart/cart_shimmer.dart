part of com.demo.market.cart.ui.views.cart;

/// Loading skeleton of the cart.
class _CartShimmer extends StatelessWidget {
  const _CartShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      key: CartKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          const AppShimmerBox(height: 96),
    ),
  );
}
