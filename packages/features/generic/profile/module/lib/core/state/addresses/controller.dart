part of com.demo.market.profile.core.state.addresses;

/// Controller of the addresses CRUD.
class AddressesViewModel extends ViewModel<AddressesState> {
  AddressesViewModel({AddressesState? state})
    : super(state ?? const AddressesState());

  @override
  void postInit() {
    service = ref.read(profileServiceProvider);
    runPostBuild(load);
  }

  late IProfileService service;

  String? get _userId => ref.read(authSessionProvider)?.id;

  Future<void> load() async {
    if (_userId == null) {
      state = state.copyWith(status: ViewStatus.empty);
      return;
    }
    state = state.copyWith(status: ViewStatus.loading, clearError: true);
    final Object? key = mountedKey;
    try {
      final List<Address> addresses = await service.addressesFor(_userId!);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        addresses: addresses,
        status: addresses.isEmpty ? ViewStatus.empty : ViewStatus.data,
        clearBusy: true,
      );
    } on Object catch (error, stackTrace) {
      log.error('profile.addresses.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  Future<void> create({
    required String label,
    required String line1,
    required String city,
    required String stateName,
    String? notes,
  }) async {
    if (_userId == null) {
      return;
    }
    await service.createAddress(
      userId: _userId!,
      label: label,
      line1: line1,
      city: city,
      state: stateName,
      notes: notes,
    );
    await load();
  }

  Future<void> update(Address address) async {
    await service.updateAddress(address);
    await load();
  }

  /// Deleting is refused while an active order references the address.
  Future<void> delete(Address address) async {
    state = state.copyWith(busyAddressId: address.id, clearError: true);
    final Object? key = mountedKey;
    try {
      await service.deleteAddress(address.id);
      if (key != mountedKey) {
        return;
      }
      await load();
    } on ProfileException catch (error) {
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(clearBusy: true, errorKey: error.code.messageKey);
    }
  }

  Future<void> setDefault(Address address) async {
    if (_userId == null) {
      return;
    }
    state = state.copyWith(busyAddressId: address.id);
    await service.setDefaultAddress(userId: _userId!, addressId: address.id);
    await load();
  }
}
