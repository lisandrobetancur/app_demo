part of com.demo.market.dashboard.core;

/// Binds [IDashboardService] to its implementation.
final Override dashboardServiceProviderOverride = dashboardServiceProvider
    .overrideWith(
      (Ref ref) =>
          DashboardService(dao: DashboardDao(ref.read(databaseProvider))),
    );
