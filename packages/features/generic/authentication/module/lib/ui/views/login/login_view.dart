part of com.demo.market.authentication.ui.views.login;

/// F04 · Login.
class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  static const String route = AuthenticationRoutes.loginPath;
  static const String name = AuthenticationRoutes.loginName;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    key: LoginKeys.view,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.xxl),
        Icon(
          AppIcons.catalog,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'authentication.login.title'.tr(),
          style: AppTypography.displayTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'authentication.login.subtitle'.tr(),
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        const _LoginForm(),
      ],
    ),
  );
}
