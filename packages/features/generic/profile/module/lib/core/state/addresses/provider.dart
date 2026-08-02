part of com.demo.market.profile.core.state.addresses;

/// Riverpod handle for [AddressesViewModel].
final NotifierProvider<AddressesViewModel, AddressesState>
addressesViewModelProvider =
    NotifierProvider<AddressesViewModel, AddressesState>(
      AddressesViewModel.new,
    );
