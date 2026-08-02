import 'dart:typed_data';

import '../models/address.dart';

/// Profile contract: personal data, avatar, addresses and account removal.
abstract interface class IProfileService {
  /// Updates name/phone and optionally the avatar image, then refreshes the
  /// active session.
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    Uint8List? avatarBytes,
  });

  /// Loads the avatar bytes of [userId], if any.
  Future<Uint8List?> avatarBytes(String userId);

  /// Addresses of [userId], default first then by label.
  Future<List<Address>> addressesFor(String userId);

  /// Creates an address (first one becomes default automatically) and
  /// returns it.
  Future<Address> createAddress({
    required String userId,
    required String label,
    required String line1,
    required String city,
    required String state,
    String? notes,
  });

  /// Updates an existing address.
  Future<void> updateAddress(Address address);

  /// Deletes an address. Throws `ProfileException` when an active order
  /// (not delivered/cancelled) still references it.
  Future<void> deleteAddress(String addressId);

  /// Marks [addressId] as the only default of [userId].
  Future<void> setDefaultAddress({
    required String userId,
    required String addressId,
  });

  /// Deletes the account and all its data (cascade), closing the session.
  Future<void> deleteAccount(String userId);
}
