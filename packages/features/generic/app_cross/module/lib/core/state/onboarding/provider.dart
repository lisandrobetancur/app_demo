part of com.demo.market.app_cross.core.state.onboarding;

/// Riverpod handle for [OnboardingViewModel].
final NotifierProvider<OnboardingViewModel, OnboardingState>
onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
