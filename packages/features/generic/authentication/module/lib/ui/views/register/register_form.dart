part of com.demo.market.authentication.ui.views.register;

/// Registration form with live validation and mandatory terms acceptance.
class _RegisterForm extends ConsumerWidget {
  const _RegisterForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegisterState state = ref.watch(registerViewModelProvider);
    final RegisterViewModel viewModel = ref.read(
      registerViewModelProvider.notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          key: RegisterKeys.fullNameInput,
          label: 'authentication.register.full_name_label'.tr(),
          textInputAction: TextInputAction.next,
          errorText: state.fullNameErrorKey?.tr(),
          onChanged: viewModel.setFullName,
        ),
        AppSpacing.formGap,
        AppTextField(
          key: RegisterKeys.emailInput,
          label: 'authentication.register.email_label'.tr(),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: state.emailErrorKey?.tr(),
          onChanged: viewModel.setEmail,
        ),
        AppSpacing.formGap,
        AppTextField(
          key: RegisterKeys.phoneInput,
          label: 'authentication.register.phone_label'.tr(),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          onChanged: viewModel.setPhone,
        ),
        AppSpacing.formGap,
        AppTextField(
          key: RegisterKeys.passwordInput,
          label: 'authentication.register.password_label'.tr(),
          obscureText: state.obscurePassword,
          textInputAction: TextInputAction.next,
          errorText: state.passwordErrorKey?.tr(),
          onChanged: viewModel.setPassword,
          suffix: IconButton(
            icon: Icon(
              state.obscurePassword
                  ? AppIcons.visibility
                  : AppIcons.visibilityOff,
            ),
            onPressed: viewModel.toggleObscurePassword,
          ),
        ),
        AppSpacing.formGap,
        AppTextField(
          key: RegisterKeys.confirmPasswordInput,
          label: 'authentication.register.confirm_password_label'.tr(),
          obscureText: state.obscurePassword,
          textInputAction: TextInputAction.done,
          errorText: state.confirmPasswordErrorKey?.tr(),
          onChanged: viewModel.setConfirmPassword,
        ),
        CheckboxListTile(
          key: RegisterKeys.termsCheckbox,
          value: state.termsAccepted,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text('authentication.register.terms_label'.tr()),
          onChanged: (bool? value) =>
              viewModel.setTermsAccepted(value ?? false),
        ),
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
        AppButton(
          key: RegisterKeys.submitButton,
          label: 'authentication.register.submit_button'.tr(),
          isLoading: state.isSubmitting,
          onPressed: state.canSubmit ? viewModel.submit : null,
          expand: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: RegisterKeys.goToLoginButton,
          label: 'authentication.register.go_to_login'.tr(),
          variant: AppButtonVariant.text,
          onPressed: viewModel.goToLogin,
        ),
      ],
    );
  }
}
