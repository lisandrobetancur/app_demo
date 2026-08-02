part of com.demo.market.profile.core;

/// Binds [IProfileService] to its implementation.
final Override profileServiceProviderOverride = profileServiceProvider
    .overrideWith(
      (Ref ref) => ProfileService(
        database: ref.read(databaseProvider),
        dao: ProfileDao(ref.read(databaseProvider)),
        idGenerator: ref.read(idGeneratorProvider),
        imageStorage: ref.read(imageStorageProvider),
        authentication: ref.read(authenticationServiceProvider),
      ),
    );
