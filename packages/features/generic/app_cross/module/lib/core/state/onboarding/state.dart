part of com.demo.market.app_cross.core.state.onboarding;

/// Immutable state of the onboarding carousel.
class OnboardingState {
  const OnboardingState({this.pageIndex = 0});

  final int pageIndex;

  bool get isLastPage => pageIndex >= AppCrossLimits.onboardingPages - 1;

  OnboardingState copyWith({int? pageIndex}) =>
      OnboardingState(pageIndex: pageIndex ?? this.pageIndex);

  @override
  bool operator ==(Object other) =>
      other is OnboardingState && other.pageIndex == pageIndex;

  @override
  int get hashCode => pageIndex.hashCode;

  @override
  String toString() => 'OnboardingState: page:$pageIndex';
}
