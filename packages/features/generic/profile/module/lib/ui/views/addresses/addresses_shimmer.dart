part of com.demo.market.profile.ui.views.addresses;

/// Loading skeleton of the addresses list.
class _AddressesShimmer extends StatelessWidget {
  const _AddressesShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      key: AddressesKeys.state('loading'),
      padding: AppSpacing.pagePadding,
      itemCount: 3,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          const AppShimmerBox(height: 128),
    ),
  );
}
