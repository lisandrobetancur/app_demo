part of com.demo.market.profile.core;

/// Concrete [IProfileService].
class ProfileService implements IProfileService {
  ProfileService({
    required AppDatabase database,
    required ProfileDao dao,
    required IdGenerator idGenerator,
    required ImageStorage imageStorage,
    required IAuthenticationService authentication,
  }) : _database = database,
       _dao = dao,
       _idGenerator = idGenerator,
       _imageStorage = imageStorage,
       _authentication = authentication;

  final AppDatabase _database;
  final ProfileDao _dao;
  final IdGenerator _idGenerator;
  final ImageStorage _imageStorage;
  final IAuthenticationService _authentication;

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    Uint8List? avatarBytes,
  }) async {
    final Map<String, Object?> values = <String, Object?>{
      'full_name': fullName.trim(),
      'phone': phone == null || phone.trim().isEmpty ? null : phone.trim(),
    };
    if (avatarBytes != null) {
      values['avatar_path'] = await _imageStorage.save(
        bytes: avatarBytes,
        imageId: 'avatar_$userId',
      );
    }
    await _dao.updateUser(userId, values);
    await _authentication.refreshSession();
  }

  @override
  Future<Uint8List?> avatarBytes(String userId) async {
    final Map<String, Object?>? row = await _dao.userById(userId);
    final String? path = row?['avatar_path'] as String?;
    if (path == null) {
      return null;
    }
    return _imageStorage.load(path);
  }

  @override
  Future<List<Address>> addressesFor(String userId) async {
    final List<Map<String, Object?>> rows = await _dao.addressesFor(userId);
    return rows.map(Address.fromMap).toList();
  }

  @override
  Future<Address> createAddress({
    required String userId,
    required String label,
    required String line1,
    required String city,
    required String state,
    String? notes,
  }) async {
    final int existing = await _dao.countAddresses(userId);
    final Address address = Address(
      id: _idGenerator.newId(),
      userId: userId,
      label: label.trim(),
      line1: line1.trim(),
      city: city.trim(),
      state: state.trim(),
      isDefault: existing == 0,
      notes: notes,
    );
    await _dao.insertAddress(address.toMap());
    return address;
  }

  @override
  Future<void> updateAddress(Address address) =>
      _dao.updateAddress(address.id, address.toMap());

  @override
  Future<void> deleteAddress(String addressId) async {
    final bool inUse = await _dao.isAddressUsedByActiveOrder(addressId);
    if (inUse) {
      throw const ProfileException(ProfileErrorCode.addressInUseByActiveOrder);
    }
    await _dao.deleteAddress(addressId);
  }

  @override
  Future<void> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    final Database database = await _database.db;
    await database.transaction((Transaction txn) async {
      await _dao.clearDefaultAddresses(txn, userId);
      await txn.update(
        DbTables.addresses,
        <String, Object?>{'is_default': 1},
        where: 'id = ?',
        whereArgs: <Object?>[addressId],
      );
    });
  }

  @override
  Future<void> deleteAccount(String userId) async {
    // Foreign keys cascade: addresses, cart, favorites, orders, reviews,
    // notifications and search history disappear with the user row.
    // Publications are owned rows without cascade, so they are logically
    // deleted first to keep historical order snapshots coherent.
    final Database database = await _database.db;
    await database.transaction((Transaction txn) async {
      await txn.update(
        DbTables.products,
        <String, Object?>{'status': 'DELETED'},
        where: 'owner_id = ?',
        whereArgs: <Object?>[userId],
      );
      await txn.delete(
        DbTables.users,
        where: 'id = ?',
        whereArgs: <Object?>[userId],
      );
    });
    await _authentication.logout();
    log.info('Account $userId deleted');
  }
}
