part of com.demo.market.app_cross.ui.views.splash;

/// Bootstrap failure with retry — the splash never hangs silently.
class _SplashError extends ConsumerWidget {
  const _SplashError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: AppSpacing.pagePadding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          AppIcons.error,
          size: 56,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'app_cross.splash.error_title'.tr(),
          style: AppTypography.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'app_cross.splash.error_message'.tr(),
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          key: AppCrossKeys.splashRetryButton,
          label: 'app_cross.splash.retry_button'.tr(),
          onPressed: ref.read(splashViewModelProvider.notifier).initialize,
        ),
      ],
    ),
  );
}
