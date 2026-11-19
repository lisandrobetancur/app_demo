part of com.demo.market.profile.ui.views.addresses;

/// Data state: address cards with default badge and actions.
class _AddressesData extends ConsumerWidget {
  const _AddressesData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AddressesState state = ref.watch(addressesViewModelProvider);
    return Column(
      children: <Widget>[
        if (state.errorKey != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Semantics(
              identifier: AddressesSemanticIds.errorText,
              child: Text(
                state.errorKey!.tr(),
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        Expanded(
          child: SemanticRegion(
            identifier: AddressesSemanticIds.state('data'),
            child: ListView.separated(
              key: AddressesKeys.state('data'),
              padding: AppSpacing.pagePadding,
              itemCount: state.addresses.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final Address address = state.addresses[index];
                return _AddressTile(
                  key: AddressesKeys.item(address.id),
                  address: address,
                  isBusy: state.busyAddressId == address.id,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// One address card.
class _AddressTile extends ConsumerWidget {
  const _AddressTile({required this.address, required this.isBusy, super.key});

  final Address address;
  final bool isBusy;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: AddressesKeys.confirmDeleteDialog,
      dialogSemanticsId: AddressesSemanticIds.deleteDialog,
      confirmSemanticsId: AddressesSemanticIds.deleteConfirmButton,
      cancelSemanticsId: AddressesSemanticIds.deleteCancelButton,
      title: 'profile.addresses.delete_title'.tr(),
      message: 'profile.addresses.delete_message'.tr(),
      confirmLabel: 'profile.addresses.confirm'.tr(),
      cancelLabel: 'profile.addresses.cancel'.tr(),
      destructive: true,
    );
    if (confirmed) {
      await ref.read(addressesViewModelProvider.notifier).delete(address);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AddressesViewModel viewModel = ref.read(
      addressesViewModelProvider.notifier,
    );
    // The card merges its texts into its own node, which takes the item's
    // identifier; the buttons inside keep nodes of their own.
    return AppCard(
      semanticsId: AddressesSemanticIds.item(address.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(address.label, style: AppTypography.cardTitle),
              ),
              if (address.isDefault)
                StatusBadge(
                  label: 'profile.addresses.default_badge'.tr(),
                  tone: StatusBadgeTone.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(address.display, style: AppTypography.body),
          if (address.notes != null)
            Text(
              address.notes!,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              if (!address.isDefault)
                TextButton(
                  key: AddressesKeys.setDefaultButton(address.id),
                  onPressed: isBusy
                      ? null
                      : () => viewModel.setDefault(address),
                  child: Semantics(
                    identifier: AddressesSemanticIds.setDefaultButton(
                      address.id,
                    ),
                    child: Text('profile.addresses.set_default_button'.tr()),
                  ),
                ),
              TextButton(
                key: AddressesKeys.editButton(address.id),
                onPressed: isBusy
                    ? null
                    : () => AppBottomSheet.show<void>(
                        context,
                        sheetKey: AddressesKeys.formSheet,
                        sheetSemanticsId: AddressesSemanticIds.formSheet,
                        child: _AddressFormSheet(existing: address),
                      ),
                child: Semantics(
                  identifier: AddressesSemanticIds.editButton(address.id),
                  child: Text('profile.addresses.edit_button'.tr()),
                ),
              ),
              TextButton(
                key: AddressesKeys.deleteButton(address.id),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: isBusy ? null : () => _confirmDelete(context, ref),
                child: Semantics(
                  identifier: AddressesSemanticIds.deleteButton(address.id),
                  child: Text('profile.addresses.delete_button'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
