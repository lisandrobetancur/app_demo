part of com.demo.market.app_cross.ui.views.onboarding;

/// One onboarding slide: illustration + title + body.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    super.key,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 64,
            backgroundColor: scheme.primaryContainer,
            child: Icon(icon, size: 64, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            titleKey.tr(),
            style: AppTypography.displayTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            bodyKey.tr(),
            style: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
