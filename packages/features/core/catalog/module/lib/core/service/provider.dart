part of com.demo.market.catalog.core;

/// Binds [ICatalogService] to its implementation.
final Override catalogServiceProviderOverride = catalogServiceProvider
    .overrideWith(
      (Ref ref) => CatalogService(
        dao: CatalogDao(ref.read(databaseProvider)),
        clock: ref.read(clockProvider),
        idGenerator: ref.read(idGeneratorProvider),
        imageStorage: ref.read(imageStorageProvider),
        favoritesCount: ref.read(favoritesCountProvider.notifier),
      ),
    );
