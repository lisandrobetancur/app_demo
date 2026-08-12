import 'package:app_cross_constants/app_cross_constants.dart';
import 'package:patrol/patrol.dart';

import 'base_page.dart';

/// F02 · Onboarding.
class OnboardingPage extends BasePage {
  const OnboardingPage(super.$);

  @override
  PatrolFinder get root => $(AppCrossKeys.onboardingView);

  PatrolFinder get skipButton => $(AppCrossKeys.onboardingSkipButton);

  PatrolFinder get nextButton => $(AppCrossKeys.onboardingNextButton);

  PatrolFinder get startButton => $(AppCrossKeys.onboardingStartButton);

  /// Slide `n`, 1-based.
  PatrolFinder slide(int n) => $(AppCrossKeys.onboardingPage(n));

  Future<void> skip() => act('onboarding_skipped', () => skipButton.tap());

  Future<void> next() => act('onboarding_next_slide', () => nextButton.tap());

  Future<void> start() => act('onboarding_started', () => startButton.tap());
}
