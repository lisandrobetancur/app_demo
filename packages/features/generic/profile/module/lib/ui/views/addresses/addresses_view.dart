part of com.demo.market.profile.ui.views.addresses;

/// F16 · Addresses CRUD.
class AddressesView extends ConsumerWidget {
  const AddressesView({super.key});

  static const String route = ProfileRoutes.addressesPath;
  static const String name = ProfileRoutes.addressesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AddressesState state = ref.watch(addressesViewModelProvider);
    return AppScaffold(
      key: AddressesKeys.view,
      title: 'profile.addresses.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton(
        key: AddressesKeys.addButton,
        tooltip: 'profile.addresses.add_button'.tr(),
        onPressed: () => AppBottomSheet.show<void>(
          context,
          sheetKey: AddressesKeys.formSheet,
          child: const _AddressFormSheet(),
        ),
        child: const Icon(AppIcons.add),
      ),
      body: switch (state.status) {
        ViewStatus.loading => const _AddressesShimmer(),
        ViewStatus.data => const _AddressesData(),
        ViewStatus.empty => const _AddressesEmpty(),
        ViewStatus.error => const _AddressesError(),
      },
    );
  }
}
