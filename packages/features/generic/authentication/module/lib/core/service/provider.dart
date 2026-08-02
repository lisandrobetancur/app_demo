part of com.demo.market.authentication.core;

/// Binds the public contract to the private implementation. The shell
/// collects every feature override when building the `ProviderContainer`.
final Override authenticationServiceProviderOverride =
    authenticationServiceProvider.overrideWith(
      (Ref ref) => AuthenticationService(
        dao: UsersDao(ref.read(databaseProvider)),
        clock: ref.read(clockProvider),
        idGenerator: ref.read(idGeneratorProvider),
        notifications: ref.read(notificationsServiceProvider),
        session: ref.read(authSessionProvider.notifier),
      ),
    );
