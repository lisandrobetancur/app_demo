part of com.demo.market.orders.core;

/// Binds [IOrdersService] to its implementation.
final Override ordersServiceProviderOverride = ordersServiceProvider
    .overrideWith(
      (Ref ref) => OrdersService(
        database: ref.read(databaseProvider),
        dao: OrdersDao(ref.read(databaseProvider)),
        clock: ref.read(clockProvider),
        idGenerator: ref.read(idGeneratorProvider),
        cartService: ref.read(cartServiceProvider),
      ),
    );
