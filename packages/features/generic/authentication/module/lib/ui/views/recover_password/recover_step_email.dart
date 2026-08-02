part of com.demo.market.authentication.ui.views.recover_password;

/// Step 1: registered email.
class _RecoverStepEmail extends ConsumerWidget {
  const _RecoverStepEmail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecoverState state = ref.watch(recoverViewModelProvider);
    final RecoverViewModel viewModel = ref.read(
      recoverViewModelProvider.notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          key: RecoverPasswordKeys.emailInput,
          label: 'authentication.recover.email_label'.tr(),
          keyboardType: TextInputType.emailAddress,
          errorText: state.emailErrorKey?.tr(),
          onChanged: viewModel.setEmail,
          onSubmitted: (String _) => viewModel.sendCode(),
        ),
        AppSpacing.formGap,
        AppButton(
          key: RecoverPasswordKeys.sendCodeButton,
          label: 'authentication.recover.send_code_button'.tr(),
          isLoading: state.isSubmitting,
          onPressed: state.canSendCode ? viewModel.sendCode : null,
          expand: true,
        ),
      ],
    );
  }
}
