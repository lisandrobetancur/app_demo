part of com.demo.market.app_cross.core;

/// Binds [INotificationsService] to its implementation.
final Override notificationsServiceProviderOverride =
    notificationsServiceProvider.overrideWith(
      (Ref ref) => NotificationsService(
        dao: NotificationsDao(ref.read(databaseProvider)),
        clock: ref.read(clockProvider),
        idGenerator: ref.read(idGeneratorProvider),
        unreadCount: ref.read(unreadNotificationsCountProvider.notifier),
        session: ref.read(authSessionProvider.notifier),
      ),
    );

/// Module-internal settings service provider (no contract needed outside).
final Provider<SettingsService> settingsServiceProvider =
    Provider<SettingsService>(
      (Ref ref) => SettingsService(
        database: ref.read(databaseProvider),
        themeMode: ref.read(themeModeProvider.notifier),
        currency: ref.read(displayCurrencyProvider.notifier),
      ),
    );
