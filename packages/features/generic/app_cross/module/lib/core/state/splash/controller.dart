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
      // The app always opens on the login screen, so a session left by an
      // earlier run is discarded here instead of restored. Dropping it — as
      // opposed to keeping it and routing to login anyway — is what stops the
      // app from holding a live session nobody has re-authenticated.
      await ref.read(authenticationServiceProvider).logout();
      final bool seenOnboarding = await ref
          .read(settingsServiceProvider)
          .hasSeenOnboarding();
      if (key != mountedKey) {
        return;
      }
      // From here on the router may resolve real routes; a deep link parked
      // during bootstrap resumes once the user has signed in.
      ref.read(bootstrapGateProvider).markReady();
      state = state.copyWith(isInitializing: false);
      if (!seenOnboarding) {
        navigatorNotifier.goToOnboarding();
      } else {
        navigatorNotifier.goToLogin();
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
