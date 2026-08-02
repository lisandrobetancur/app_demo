part of com.demo.market.authentication.ui.views.recover_password;

/// Step 3: new password and confirmation.
class _RecoverStepPassword extends ConsumerWidget {
  const _RecoverStepPassword();

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
          key: RecoverPasswordKeys.newPasswordInput,
          label: 'authentication.recover.new_password_label'.tr(),
          obscureText: true,
          textInputAction: TextInputAction.next,
          errorText: state.newPasswordErrorKey?.tr(),
          onChanged: viewModel.setNewPassword,
        ),
        AppSpacing.formGap,
        AppTextField(
          key: RecoverPasswordKeys.confirmNewPasswordInput,
          label: 'authentication.recover.confirm_new_password_label'.tr(),
          obscureText: true,
          textInputAction: TextInputAction.done,
          errorText: state.confirmPasswordErrorKey?.tr(),
          onChanged: viewModel.setConfirmPassword,
          onSubmitted: (String _) => viewModel.submitNewPassword(),
        ),
        AppSpacing.formGap,
        AppButton(
          key: RecoverPasswordKeys.submitButton,
          label: 'authentication.recover.submit_button'.tr(),
          isLoading: state.isSubmitting,
          onPressed: state.canSubmitPassword
              ? viewModel.submitNewPassword
              : null,
          expand: true,
        ),
      ],
    );
  }
}
