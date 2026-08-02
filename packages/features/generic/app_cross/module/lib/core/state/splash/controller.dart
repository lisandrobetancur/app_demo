part of com.demo.market.app_cross.core.state.splash;

/// Bootstrap controller: opens the database, restores settings and session,
/// then routes to onboarding, login or dashboard.
class SplashViewModel extends ViewModel<SplashState> {
  SplashViewModel({SplashState? state}) : super(state ?? const SplashState());

  @override
  void postInit() {
    navigatorNotifier = ref.read(appCrossNavigator.notifier);
    runPostBuild(initialize);
  }

  late AppCrossNavigator navigatorNotifier;

  Future<void> initialize() async {
    state = state.copyWith(isInitializing: true, hasError: false);
    final Object? key = mountedKey;
    try {
      // Opening the connection also creates/seeds the schema on first run.
      await ref.read(databaseProvider).db;
      await ref.read(settingsServiceProvider).restore();
      final AuthUser? user = await ref
          .read(authenticationServiceProvider)
          .restoreSession();
      final bool seenOnboarding = await ref
          .read(settingsServiceProvider)
          .hasSeenOnboarding();
      if (user != null) {
        await ref
            .read(notificationsServiceProvider)
            .refreshUnreadCount(user.id);
      }
      if (key != mountedKey) {
        return;
      }
      // From here on the router may resolve real routes; a deep link parked
      // during bootstrap resumes as soon as there is a session.
      ref.read(bootstrapGateProvider).markReady();
      state = state.copyWith(isInitializing: false);
      if (!seenOnboarding) {
        navigatorNotifier.goToOnboarding();
      } else if (user == null) {
        navigatorNotifier.goToLogin();
      } else {
        navigatorNotifier.goToDashboard();
      }
    } on Object catch (error, stackTrace) {
      log.error('splash.initialize', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isInitializing: false, hasError: true);
    }
  }
}
