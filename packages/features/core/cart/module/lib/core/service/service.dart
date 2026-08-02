part of com.demo.market.cart.core;

/// Concrete [ICartService].
///
/// The checkout is the critical transaction of the app: order + item
/// snapshots + stock decrement + cart cleanup + notification, all inside a
/// single SQLite transaction — a failure at any point leaves everything
/// untouched.
class CartService implements ICartService {
  CartService({
    required AppDatabase database,
    required CartDao dao,
    required Clock clock,
    required IdGenerator idGenerator,
    required ImageStorage imageStorage,
    required StateController<int> itemCount,
    required StateController<double> subtotal,
  }) : _database = database,
       _dao = dao,
       _clock = clock,
       _idGenerator = idGenerator,
       _imageStorage = imageStorage,
       _itemCount = itemCount,
       _subtotal = subtotal;

  final AppDatabase _database;
  final CartDao _dao;
  final Clock _clock;
  final IdGenerator _idGenerator;
  final ImageStorage _imageStorage;
  final StateController<int> _itemCount;
  final StateController<double> _subtotal;

  @override
  Future<List<CartLine>> linesFor(String userId) async {
    final List<Map<String, Object?>> rows = await _dao.linesFor(userId);
    final List<CartLine> lines = <CartLine>[];
    for (final Map<String, Object?> row in rows) {
      lines.add(await _hydrate(row));
    }
    await refreshBadge(userId);
    return lines;
  }

  @override
  Future<void> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    final Map<String, Object?>? existing = await _dao.lineByProduct(
      userId: userId,
      productId: productId,
    );
    if (existing == null) {
      await _dao.insertLine(<String, Object?>{
        'id': _idGenerator.newId(),
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
        'added_at': _clock().millisecondsSinceEpoch,
      });
    } else {
      await _dao.updateQuantity(
        cartItemId: existing['id']! as String,
        quantity: (existing['quantity']! as int) + quantity,
      );
    }
    await refreshBadge(userId);
  }

  @override
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) => _dao.updateQuantity(cartItemId: cartItemId, quantity: quantity);

  @override
  Future<void> removeLine(String cartItemId) => _dao.deleteLine(cartItemId);

  @override
  Future<void> clear(String userId) async {
    await _dao.clear(userId);
    await refreshBadge(userId);
  }

  @override
  Future<Coupon> validateCoupon({
    required String code,
    required double subtotal,
  }) async {
    final Map<String, Object?>? row = await _dao.couponByCode(
      code.trim().toUpperCase(),
    );
    if (row == null) {
      throw const CouponException(CouponErrorCode.notFound);
    }
    final Coupon coupon = Coupon.fromMap(row);
    if (!coupon.isActive) {
      throw const CouponException(CouponErrorCode.inactive);
    }
    if (coupon.validUntil.isBefore(_clock())) {
      throw const CouponException(CouponErrorCode.expired);
    }
    if (subtotal < coupon.minAmount) {
      throw const CouponException(CouponErrorCode.minAmountNotReached);
    }
    return coupon;
  }

  @override
  Future<String> checkout({
    required String userId,
    required PaymentMethod paymentMethod,
    String? addressId,
    String? couponCode,
  }) async {
    final Database database = await _database.db;
    final String orderId = _idGenerator.newId();
    final int now = _clock().millisecondsSinceEpoch;
    await database.transaction((Transaction txn) async {
      final List<Map<String, Object?>> lines = await txn.rawQuery(
        'SELECT ci.id, ci.product_id, ci.quantity, '
        'p.name, p.price, p.stock, p.status '
        'FROM ${DbTables.cartItems} ci '
        'JOIN ${DbTables.products} p ON p.id = ci.product_id '
        'WHERE ci.user_id = ? ORDER BY ci.added_at ASC, ci.id ASC',
        <Object?>[userId],
      );
      if (lines.isEmpty) {
        throw const CartException(CartErrorCode.emptyCart);
      }
      double subtotal = 0;
      for (final Map<String, Object?> line in lines) {
        final int quantity = line['quantity']! as int;
        final int stock = line['stock']! as int;
        final String status = line['status']! as String;
        if (status != 'ACTIVE' || quantity > stock) {
          throw const CartException(CartErrorCode.outOfStock);
        }
        subtotal += (line['price']! as num).toDouble() * quantity;
      }
      Coupon? coupon;
      if (couponCode != null) {
        final List<Map<String, Object?>> couponRows = await txn.query(
          DbTables.coupons,
          where: 'code = ?',
          whereArgs: <Object?>[couponCode],
          limit: 1,
        );
        if (couponRows.isNotEmpty) {
          coupon = Coupon.fromMap(couponRows.first);
        }
      }
      final double discount = coupon?.discountFor(subtotal) ?? 0;
      final double taxable = subtotal - discount;
      final double tax = taxable * CartLimits.taxRate;
      await txn.insert(DbTables.orders, <String, Object?>{
        'id': orderId,
        'user_id': userId,
        'address_id': addressId,
        'coupon_code': coupon?.code,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': taxable + tax,
        'payment_method': paymentMethod.dbValue,
        'status': 'CREATED',
        'created_at': now,
      });
      for (final Map<String, Object?> line in lines) {
        final int quantity = line['quantity']! as int;
        await txn.insert(DbTables.orderItems, <String, Object?>{
          'id': _idGenerator.newId(),
          'order_id': orderId,
          'product_id': line['product_id'],
          'name': line['name'],
          'unit_price': line['price'],
          'quantity': quantity,
        });
        await txn.rawUpdate(
          'UPDATE ${DbTables.products} SET stock = stock - ?, '
          'updated_at = ? WHERE id = ?',
          <Object?>[quantity, now, line['product_id']],
        );
      }
      await txn.delete(
        DbTables.cartItems,
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
      );
      await txn.insert(DbTables.notifications, <String, Object?>{
        'id': _idGenerator.newId(),
        'user_id': userId,
        'type': 'ORDER_CREATED',
        'title_key': 'app_cross.notifications.order_created_title',
        'body_key': 'app_cross.notifications.order_created_body',
        'payload':
            '{"route":"/orders/detail/$orderId",'
            '"args":{"orderNumber":'
            '"${orderId.substring(0, 8).toUpperCase()}"}}',
        'is_read': 0,
        'created_at': now,
      });
    });
    await refreshBadge(userId);
    log.info('Checkout completed: order $orderId');
    return orderId;
  }

  @override
  Future<void> refreshBadge(String userId) async {
    final (int lines, double subtotal) = await _dao.badgeFor(userId);
    _itemCount.state = lines;
    _subtotal.state = subtotal;
  }

  Future<CartLine> _hydrate(Map<String, Object?> row) async {
    final String? imagePath = row['image_path'] as String?;
    return CartLine(
      id: row['id']! as String,
      productId: row['product_id']! as String,
      productName: row['product_name']! as String,
      unitPrice: (row['unit_price']! as num).toDouble(),
      stock: row['stock']! as int,
      quantity: row['quantity']! as int,
      productStatus: ProductStatus.parse(row['product_status']! as String),
      addedAt: DateTime.fromMillisecondsSinceEpoch(row['added_at']! as int),
      categoryCode: (row['category_code'] as String?) ?? '',
      imageBytes: imagePath == null
          ? null
          : await _imageStorage.load(imagePath),
    );
  }
}
