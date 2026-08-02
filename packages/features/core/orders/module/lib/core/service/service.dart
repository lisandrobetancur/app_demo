part of com.demo.market.orders.core;

/// Concrete [IOrdersService].
///
/// Cancellation is transactional: status change + stock restitution +
/// notification, all or nothing. Re-order delegates cart writes to the cart
/// contract and reports unavailable products.
class OrdersService implements IOrdersService {
  OrdersService({
    required AppDatabase database,
    required OrdersDao dao,
    required Clock clock,
    required IdGenerator idGenerator,
    required ICartService cartService,
  }) : _database = database,
       _dao = dao,
       _clock = clock,
       _idGenerator = idGenerator,
       _cartService = cartService;

  final AppDatabase _database;
  final OrdersDao _dao;
  final Clock _clock;
  final IdGenerator _idGenerator;
  final ICartService _cartService;

  @override
  @override
  Future<List<Order>> ordersFor(
    String userId, {
    OrderStatus? status,
    String query = '',
  }) async {
    final List<Map<String, Object?>> rows = await _dao.ordersFor(
      userId,
      statusDbValue: status?.dbValue,
    );
    final List<Order> orders = <Order>[];
    for (final Map<String, Object?> row in rows) {
      final List<Map<String, Object?>> itemRows = await _dao.itemsFor(
        row['id']! as String,
      );
      orders.add(
        Order.fromMap(row, items: itemRows.map(OrderItem.fromMap).toList()),
      );
    }
    final String normalized = query.trim().toUpperCase();
    if (normalized.isEmpty) {
      return orders;
    }
    return orders
        .where((Order order) => order.number.contains(normalized))
        .toList();
  }

  @override
  Future<Order?> orderById(String orderId) async {
    final Map<String, Object?>? row = await _dao.orderById(orderId);
    if (row == null) {
      return null;
    }
    final List<Map<String, Object?>> itemRows = await _dao.itemsFor(orderId);
    return Order.fromMap(row, items: itemRows.map(OrderItem.fromMap).toList());
  }

  @override
  Future<int> countOrdersInMonth(String userId, DateTime reference) {
    final DateTime from = DateTime(reference.year, reference.month);
    final DateTime to = DateTime(reference.year, reference.month + 1);
    return _dao.countInRange(
      userId: userId,
      fromMillis: from.millisecondsSinceEpoch,
      toMillis: to.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    final Order? order = await orderById(orderId);
    if (order == null) {
      throw StateError('Order not found: $orderId');
    }
    if (!order.status.isCancellable) {
      throw StateError('Order ${order.number} cannot be cancelled');
    }
    final Database database = await _database.db;
    final int now = _clock().millisecondsSinceEpoch;
    await database.transaction((Transaction txn) async {
      await txn.update(
        DbTables.orders,
        <String, Object?>{'status': OrderStatus.cancelled.dbValue},
        where: 'id = ?',
        whereArgs: <Object?>[orderId],
      );
      for (final OrderItem item in order.items) {
        await txn.rawUpdate(
          'UPDATE ${DbTables.products} SET stock = stock + ?, '
          'updated_at = ? WHERE id = ?',
          <Object?>[item.quantity, now, item.productId],
        );
      }
      await txn.insert(DbTables.notifications, <String, Object?>{
        'id': _idGenerator.newId(),
        'user_id': order.userId,
        'type': 'ORDER_STATUS',
        'title_key': 'app_cross.notifications.order_cancelled_title',
        'body_key': 'app_cross.notifications.order_cancelled_body',
        'payload':
            '{"route":"/orders/detail/$orderId",'
            '"args":{"orderNumber":"${order.number}"}}',
        'is_read': 0,
        'created_at': now,
      });
    });
    log.info('Order $orderId cancelled, stock restored');
  }

  @override
  Future<ReorderResult> reorder({
    required String orderId,
    required String userId,
  }) async {
    final Order? order = await orderById(orderId);
    if (order == null) {
      throw StateError('Order not found: $orderId');
    }
    final Database database = await _database.db;
    int addedCount = 0;
    final List<String> unavailable = <String>[];
    for (final OrderItem item in order.items) {
      final List<Map<String, Object?>> rows = await database.query(
        DbTables.products,
        columns: <String>['stock', 'status'],
        where: 'id = ?',
        whereArgs: <Object?>[item.productId],
        limit: 1,
      );
      final bool available =
          rows.isNotEmpty &&
          rows.first['status'] == 'ACTIVE' &&
          (rows.first['stock']! as int) > 0;
      if (!available) {
        unavailable.add(item.name);
        continue;
      }
      final int stock = rows.first['stock']! as int;
      await _cartService.addToCart(
        userId: userId,
        productId: item.productId,
        quantity: item.quantity <= stock ? item.quantity : stock,
      );
      addedCount++;
    }
    return ReorderResult(addedCount: addedCount, unavailableNames: unavailable);
  }
}
