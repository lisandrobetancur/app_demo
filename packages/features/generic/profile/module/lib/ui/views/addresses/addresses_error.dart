part of com.demo.market.profile.ui.views.addresses;

/// Error state with retry.
class _AddressesError extends ConsumerWidget {
  const _AddressesError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: AddressesKeys.state('error'),
    icon: AppIcons.error,
    title: 'profile.addresses.error_title'.tr(),
    actionLabel: 'profile.addresses.retry_button'.tr(),
    onAction: ref.read(addressesViewModelProvider.notifier).load,
  );
}
