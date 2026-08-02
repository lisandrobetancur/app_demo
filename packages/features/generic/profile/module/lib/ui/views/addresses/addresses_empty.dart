part of com.demo.market.profile.ui.views.addresses;

/// Empty state of the addresses list.
class _AddressesEmpty extends StatelessWidget {
  const _AddressesEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: AddressesKeys.state('empty'),
    icon: AppIcons.address,
    title: 'profile.addresses.empty_title'.tr(),
    message: 'profile.addresses.empty_message'.tr(),
  );
}
