part of com.demo.market.profile.core.state.addresses;

/// Immutable state of the addresses screen (F16).
class AddressesState {
  const AddressesState({
    this.addresses = const <Address>[],
    this.status = ViewStatus.loading,
    this.busyAddressId,
    this.errorKey,
  });

  final List<Address> addresses;
  final ViewStatus status;

  /// Address with an in-flight action.
  final String? busyAddressId;

  final String? errorKey;

  AddressesState copyWith({
    List<Address>? addresses,
    ViewStatus? status,
    String? busyAddressId,
    String? errorKey,
    bool clearBusy = false,
    bool clearError = false,
  }) => AddressesState(
    addresses: addresses ?? this.addresses,
    status: status ?? this.status,
    busyAddressId: clearBusy ? null : busyAddressId ?? this.busyAddressId,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is AddressesState &&
      other.status == status &&
      other.busyAddressId == busyAddressId &&
      other.errorKey == errorKey &&
      other.addresses.length == addresses.length &&
      _sameAddresses(other.addresses, addresses);

  @override
  int get hashCode =>
      Object.hash(status, busyAddressId, errorKey, Object.hashAll(addresses));

  @override
  String toString() =>
      'AddressesState: ${addresses.length} items ${status.name}';

  static bool _sameAddresses(List<Address> a, List<Address> b) {
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
