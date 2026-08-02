part of com.demo.market.app_cross.ui.views.splash;

/// F01 · Splash / bootstrap.
class SplashView extends ConsumerWidget {
  const SplashView({super.key});

  static const String route = AppCrossRoutes.splashPath;
  static const String name = AppCrossRoutes.splashName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SplashState state = ref.watch(splashViewModelProvider);
    return Scaffold(
      key: AppCrossKeys.splashView,
      body: Center(
        child: state.hasError
            ? const _SplashError()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    AppIcons.catalog,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'app_cross.splash.loading'.tr(),
                    style: AppTypography.body,
                  ),
                ],
              ),
      ),
    );
  }
}
