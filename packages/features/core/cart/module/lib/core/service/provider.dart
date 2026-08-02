part of com.demo.market.cart.core;

/// Binds [ICartService] to its implementation.
final Override cartServiceProviderOverride = cartServiceProvider.overrideWith(
  (Ref ref) => CartService(
    database: ref.read(databaseProvider),
    dao: CartDao(ref.read(databaseProvider)),
    clock: ref.read(clockProvider),
    idGenerator: ref.read(idGeneratorProvider),
    imageStorage: ref.read(imageStorageProvider),
    itemCount: ref.read(cartItemCountProvider.notifier),
    subtotal: ref.read(cartSubtotalProvider.notifier),
  ),
);
