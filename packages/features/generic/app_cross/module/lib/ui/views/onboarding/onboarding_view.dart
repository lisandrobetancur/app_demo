part of com.demo.market.app_cross.ui.views.onboarding;

/// F02 · Onboarding (3 slides, first launch only).
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  static const String route = AppCrossRoutes.onboardingPath;
  static const String name = AppCrossRoutes.onboardingName;

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();

  static const List<IconData> _icons = <IconData>[
    AppIcons.categoryCar,
    AppIcons.search,
    AppIcons.cart,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (AppDurations.medium == Duration.zero) {
      _pageController.jumpToPage(page);
      return;
    }
    _pageController.animateToPage(
      page,
      duration: AppDurations.medium,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingState state = ref.watch(onboardingViewModelProvider);
    final OnboardingViewModel viewModel = ref.read(
      onboardingViewModelProvider.notifier,
    );
    return Scaffold(
      key: AppCrossKeys.onboardingView,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: AppCrossKeys.onboardingSkipButton,
                onPressed: viewModel.finish,
                child: Text('app_cross.onboarding.skip_button'.tr()),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: viewModel.setPage,
                children: <Widget>[
                  for (
                    int page = 1;
                    page <= AppCrossLimits.onboardingPages;
                    page++
                  )
                    _OnboardingPage(
                      key: AppCrossKeys.onboardingPage(page),
                      icon: _icons[page - 1],
                      titleKey: 'app_cross.onboarding.page_${page}_title',
                      bodyKey: 'app_cross.onboarding.page_${page}_body',
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (
                  int index = 0;
                  index < AppCrossLimits.onboardingPages;
                  index++
                )
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: index == state.pageIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: AppSpacing.pagePadding,
              child: state.isLastPage
                  ? AppButton(
                      key: AppCrossKeys.onboardingStartButton,
                      label: 'app_cross.onboarding.start_button'.tr(),
                      onPressed: viewModel.finish,
                      expand: true,
                    )
                  : AppButton(
                      key: AppCrossKeys.onboardingNextButton,
                      label: 'app_cross.onboarding.next_button'.tr(),
                      onPressed: () => _goToPage(state.pageIndex + 1),
                      expand: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
