part of com.demo.market.cart.ui.views.checkout;

/// Step 1: choose a saved address or create one inline.
class _CheckoutStepDelivery extends ConsumerWidget {
  const _CheckoutStepDelivery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckoutState state = ref.watch(checkoutViewModelProvider);
    final CheckoutViewModel viewModel = ref.read(
      checkoutViewModelProvider.notifier,
    );
    return ListView(
      padding: AppSpacing.pagePadding,
      children: <Widget>[
        Text(
          state.addresses.isEmpty
              ? 'cart.checkout.no_addresses'.tr()
              : 'cart.checkout.choose_address'.tr(),
          style: AppTypography.cardTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final Address address in state.addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              key: CheckoutKeys.addressOption(address.id),
              onTap: () => viewModel.selectAddress(address.id),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Icon(
                    state.selectedAddressId == address.id
                        ? AppIcons.checkFilled
                        : AppIcons.address,
                    color: state.selectedAddressId == address.id
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(address.label, style: AppTypography.cardTitle),
                        Text(address.display, style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: CheckoutKeys.addAddressButton,
          label: 'cart.checkout.add_address_button'.tr(),
          icon: AppIcons.add,
          variant: AppButtonVariant.secondary,
          onPressed: () => AppBottomSheet.show<void>(
            context,
            child: const _CheckoutAddressForm(),
          ),
        ),
      ],
    );
  }
}
