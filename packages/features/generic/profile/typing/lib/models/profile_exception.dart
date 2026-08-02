/// Typed profile failures.
enum ProfileErrorCode {
  /// Deleting an address referenced by an order that is still in progress.
  addressInUseByActiveOrder;

  bool get isAddressInUse => this == ProfileErrorCode.addressInUseByActiveOrder;

  /// Translation key of the error message.
  String get messageKey => switch (this) {
    ProfileErrorCode.addressInUseByActiveOrder =>
      'profile.addresses.error_in_use',
  };
}

/// Exception carrying a [ProfileErrorCode].
class ProfileException implements Exception {
  const ProfileException(this.code);

  final ProfileErrorCode code;

  @override
  String toString() => 'ProfileException: ${code.name}';
}
