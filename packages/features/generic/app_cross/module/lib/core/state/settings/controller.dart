part of com.demo.market.app_cross.core.state.settings;

/// Controller of the settings screen.
class SettingsViewModel extends ViewModel<SettingsState> {
  SettingsViewModel({SettingsState? state})
    : super(state ?? const SettingsState());

  @override
  void postInit() {
    service = ref.read(settingsServiceProvider);
    navigatorNotifier = ref.read(appCrossNavigator.notifier);
  }

  late SettingsService service;
  late AppCrossNavigator navigatorNotifier;

  Future<void> setThemeMode(ThemeMode mode) => service.setThemeMode(mode);

  Future<void> setCurrency(DisplayCurrency currency) =>
      service.setCurrency(currency);

  /// Re-enables onboarding and opens it right away.
  Future<void> seeOnboardingAgain() async {
    await service.resetOnboardingFlag();
    navigatorNotifier.goToOnboarding();
  }

  /// Restores the deterministic demo content. The active session may point
  /// to a user that no longer exists afterwards, so it closes the session.
  Future<void> resetDemoData() => _runMaintenance(service.resetToSeed);

  /// Deletes every row. Also closes the session.
  Future<void> wipeData() => _runMaintenance(service.wipe);

  Future<void> _runMaintenance(Future<void> Function() action) async {
    state = state.copyWith(isBusy: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await action();
      await ref.read(authenticationServiceProvider).logout();
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isBusy: false);
      navigatorNotifier.goToLogin();
    } on Object catch (error, stackTrace) {
      log.error('settings.maintenance', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isBusy: false,
        errorKey: 'app_cross.settings.maintenance_error',
      );
    }
  }
}
