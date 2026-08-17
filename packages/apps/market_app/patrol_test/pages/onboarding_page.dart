import 'package:app_cross_constants/app_cross_constants.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_kit/patrol_kit.dart';


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

  Future<void> skip() => skipButton.tap();

  Future<void> next() => nextButton.tap();

  Future<void> start() => startButton.tap();
}
