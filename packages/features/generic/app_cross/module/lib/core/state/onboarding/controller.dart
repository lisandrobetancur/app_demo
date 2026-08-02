part of com.demo.market.app_cross.core.state.onboarding;

/// Controller of the onboarding carousel.
class OnboardingViewModel extends ViewModel<OnboardingState> {
  OnboardingViewModel({OnboardingState? state})
    : super(state ?? const OnboardingState());

  @override
  void postInit() {
    navigatorNotifier = ref.read(appCrossNavigator.notifier);
  }

  late AppCrossNavigator navigatorNotifier;

  void setPage(int index) => state = state.copyWith(pageIndex: index);

  /// Marks the onboarding as seen and leaves it (skip or start).
  Future<void> finish() async {
    await ref.read(settingsServiceProvider).markOnboardingSeen();
    final AuthUser? user = ref.read(authSessionProvider);
    if (user == null) {
      navigatorNotifier.goToLogin();
    } else {
      navigatorNotifier.goToDashboard();
    }
  }
}
