part of com.demo.market.authentication.ui.views.recover_password;

/// F05 · Password recovery (3 steps).
class RecoverPasswordView extends ConsumerWidget {
  const RecoverPasswordView({super.key});

  static const String route = AuthenticationRoutes.recoverPasswordPath;
  static const String name = AuthenticationRoutes.recoverPasswordName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecoverState state = ref.watch(recoverViewModelProvider);
    final RecoverViewModel viewModel = ref.read(
      recoverViewModelProvider.notifier,
    );
    ref.listen<RecoverState>(recoverViewModelProvider, (
      RecoverState? previous,
      RecoverState next,
    ) {
      if (next.completed && previous?.completed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('authentication.recover.success_message'.tr()),
          ),
        );
        viewModel.backToLogin();
      }
    });
    return AppScaffold(
      key: RecoverPasswordKeys.view,
      title: 'authentication.recover.title'.tr(),
      leading: BackButton(onPressed: viewModel.backToLogin),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StepperHeader(
            steps: <String>[
              'authentication.recover.step_email'.tr(),
              'authentication.recover.step_code'.tr(),
              'authentication.recover.step_password'.tr(),
            ],
            currentIndex: state.step.index,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.errorKey != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                state.errorKey!.tr(),
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          switch (state.step) {
            RecoverStep.email => const _RecoverStepEmail(),
            RecoverStep.code => const _RecoverStepCode(),
            RecoverStep.password => const _RecoverStepPassword(),
          },
        ],
      ),
    );
  }
}
