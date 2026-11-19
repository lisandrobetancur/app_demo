part of com.demo.market.authentication.ui.views.login;

/// Email/password form with remember-me and inline errors.
class _LoginForm extends ConsumerWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoginState state = ref.watch(loginViewModelProvider);
    final LoginViewModel viewModel = ref.read(loginViewModelProvider.notifier);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: LoginKeys.emailInput,
            semanticsId: LoginSemanticIds.emailInput,
            label: 'authentication.login.email_label'.tr(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
            errorText: state.emailErrorKey?.tr(),
            onChanged: viewModel.setEmail,
          ),
          AppSpacing.formGap,
          AppTextField(
            key: LoginKeys.passwordInput,
            semanticsId: LoginSemanticIds.passwordInput,
            label: 'authentication.login.password_label'.tr(),
            obscureText: state.obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
            onChanged: viewModel.setPassword,
            onSubmitted: (String _) => viewModel.submit(),
            suffix: Semantics(
              identifier: LoginSemanticIds.togglePasswordVisibilityButton,
              label: state.obscurePassword
                  ? 'authentication.login.show_password'.tr()
                  : 'authentication.login.hide_password'.tr(),
              button: true,
              child: IconButton(
                key: LoginKeys.togglePasswordVisibilityButton,
                icon: Icon(
                  state.obscurePassword
                      ? AppIcons.visibility
                      : AppIcons.visibilityOff,
                ),
                onPressed: viewModel.toggleObscurePassword,
              ),
            ),
          ),
          if (state.errorKey != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Semantics(
                identifier: LoginSemanticIds.errorText,
                child: Text(
                  state.errorKey!.tr(),
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          AppButton(
            key: LoginKeys.submitButton,
            semanticsId: LoginSemanticIds.submitButton,
            label: 'authentication.login.submit_button'.tr(),
            isLoading: state.isSubmitting,
            onPressed: state.canSubmit ? viewModel.submit : null,
            expand: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: LoginKeys.goToRegisterButton,
            semanticsId: LoginSemanticIds.goToRegisterButton,
            label: 'authentication.login.go_to_register'.tr(),
            variant: AppButtonVariant.secondary,
            onPressed: () => ref
                .read(loginViewModelProvider.notifier)
                .navigatorNotifier
                .goToRegister(),
            expand: true,
          ),
          AppButton(
            key: LoginKeys.goToRecoverPasswordButton,
            semanticsId: LoginSemanticIds.goToRecoverPasswordButton,
            label: 'authentication.login.go_to_recover'.tr(),
            variant: AppButtonVariant.text,
            onPressed: () => ref
                .read(loginViewModelProvider.notifier)
                .navigatorNotifier
                .goToRecoverPassword(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'authentication.login.demo_hint'.tr(),
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
