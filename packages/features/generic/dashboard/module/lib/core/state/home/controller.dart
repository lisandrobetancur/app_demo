part of com.demo.market.dashboard.core.state.home;

/// Controller of the dashboard home.
class HomeViewModel extends ViewModel<HomeState> {
  HomeViewModel({HomeState? state}) : super(state ?? const HomeState());

  @override
  void postInit() {
    service = ref.read(dashboardServiceProvider);
    navigatorNotifier = ref.read(dashboardNavigator.notifier);
    runPostBuild(load);
  }

  late IDashboardService service;
  late DashboardNavigator navigatorNotifier;

  /// Full refresh (pull-to-refresh on mobile, refresh button on web).
  Future<void> load() async {
    final AuthUser? user = ref.read(authSessionProvider);
    if (user == null) {
      state = state.copyWith(status: ViewStatus.empty);
      return;
    }
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final ICatalogService catalog = ref.read(catalogServiceProvider);
      final DashboardSummary summary = await service.summaryFor(
        userId: user.id,
        reference: ref.read(clockProvider)(),
      );
      final List<Category> categories = await catalog.getCategories();
      final List<Product> recents = await catalog.getRecentProducts(limit: 10);
      // The badge this view renders used to be filled at bootstrap, when a
      // restored session was still a thing. Now that every run starts logged
      // out, the dashboard loads its own counter — which also keeps it fresh
      // on every refresh rather than only once per launch.
      await ref.read(notificationsServiceProvider).refreshUnreadCount(user.id);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        summary: summary,
        categories: categories,
        recentProducts: recents,
        status: ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('dashboard.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }
}
