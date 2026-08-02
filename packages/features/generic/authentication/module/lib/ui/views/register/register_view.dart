part of com.demo.market.authentication.ui.views.register;

/// F03 · Registration.
class RegisterView extends ConsumerWidget {
  const RegisterView({super.key});

  static const String route = AuthenticationRoutes.registerPath;
  static const String name = AuthenticationRoutes.registerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    key: RegisterKeys.view,
    title: 'authentication.register.title'.tr(),
    body: const _RegisterForm(),
  );
}
